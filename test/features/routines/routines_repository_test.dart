import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/routines/data/routines_repository.dart';

void main() {
  late Database testDb;
  late RoutinesRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: SchemaConstants.databaseVersion,
        onConfigure: DatabaseMigrations.onConfigure,
        onCreate: DatabaseMigrations.onCreate,
        onUpgrade: DatabaseMigrations.onUpgrade,
      ),
    );
    AppDatabase.instance.setDatabaseForTesting(testDb);
    repository = RoutinesRepository(db: AppDatabase.instance);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('RoutinesRepository', () {
    test('getAllRoutines automatically seeds default routines if database is empty', () async {
      final routines = await repository.getAllRoutines();
      expect(routines.length, 4);
      expect(routines.any((r) => r.name == 'College Prep' && r.category == 'college'), isTrue);
      expect(routines.any((r) => r.name == 'Daily Commute' && r.category == 'office'), isTrue);
      expect(routines.any((r) => r.name == 'Gym Session' && r.category == 'gym'), isTrue);
      expect(routines.any((r) => r.name == 'Weekend Travel' && r.category == 'travel'), isTrue);
    });

    test('getAllRoutines filters by category correctly', () async {
      final collegeRoutines = await repository.getAllRoutines(category: 'college');
      expect(collegeRoutines.length, 1);
      expect(collegeRoutines.first.name, 'College Prep');

      final officeRoutines = await repository.getAllRoutines(category: 'office');
      expect(officeRoutines.length, 1);
      expect(officeRoutines.first.name, 'Daily Commute');
    });

    test('createRoutine, addItemToRoutine, toggle verification and reset checklist', () async {
      // 1. Create a routine with category and scheduled reminder
      final routine = await repository.createRoutine(
        name: 'Evening Gym Routine',
        iconName: 'fitness_center',
        category: 'gym',
        scheduledTime: '06:00 PM',
        isReminderEnabled: true,
        description: 'Water bottle, wrist wraps, lock',
      );
      expect(routine.name, 'Evening Gym Routine');
      expect(routine.category, 'gym');
      expect(routine.scheduledTime, '06:00 PM');
      expect(routine.isReminderEnabled, isTrue);

      // 2. Insert test item identity
      await testDb.insert(SchemaConstants.tableItemIdentities, {
        SchemaConstants.colId: 'item-101',
        SchemaConstants.colName: 'Metal Water Bottle',
        SchemaConstants.colCategory: 'Drinkware',
        SchemaConstants.colLastObservedLocation: 'Kitchen Counter',
        SchemaConstants.colLastObservedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        SchemaConstants.colCreatedAt: DateTime.now().toIso8601String(),
      });

      // 3. Add item to routine
      final routineItemId = await repository.addItemToRoutine(routine.id, 'item-101');
      expect(routineItemId, isNotEmpty);

      // 4. Retrieve items in routine
      var items = await repository.getRoutineItems(routine.id);
      expect(items.length, 1);
      final item = items.first;
      expect(item.itemName, 'Metal Water Bottle');
      expect(item.isVerifiedPacked, isFalse);
      expect(item.lastObservedLocation, 'Kitchen Counter');
      // Crucial requirement: Must never claim an item is packed unless user-verified
      expect(item.statusMessage, contains('Historical sighting: Kitchen Counter'));
      expect(item.statusMessage, contains('NOT verified packed'));

      // 5. User confirms item is packed
      await repository.setItemVerifiedPacked(routineItemId, true);
      items = await repository.getRoutineItems(routine.id);
      expect(items.first.isVerifiedPacked, isTrue);
      expect(items.first.statusMessage, contains('Verified packed by user'));

      // Verify aggregate count on routine
      final updatedRoutine = await repository.getRoutineById(routine.id);
      expect(updatedRoutine?.totalItems, 1);
      expect(updatedRoutine?.verifiedItems, 1);
      expect(updatedRoutine?.isFullyVerified, isTrue);

      // 6. Reset routine checklist for next departure
      await repository.resetAllVerifications(routine.id);
      items = await repository.getRoutineItems(routine.id);
      expect(items.first.isVerifiedPacked, isFalse);

      // 7. Remove item from routine
      await repository.removeItemFromRoutine(routineItemId);
      items = await repository.getRoutineItems(routine.id);
      expect(items.isEmpty, isTrue);

      // 8. Delete routine
      await repository.deleteRoutine(routine.id);
      final deleted = await repository.getRoutineById(routine.id);
      expect(deleted, isNull);
    });
  });
}
