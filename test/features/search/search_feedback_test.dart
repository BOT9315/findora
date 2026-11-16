import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/search/data/search_feedback_repository.dart';

void main() {
  late Database testDb;
  late SearchFeedbackRepository repository;

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
    repository = SearchFeedbackRepository(db: AppDatabase.instance);

    // Insert mock memories to satisfy foreign key constraints
    final now = DateTime.now().toIso8601String();
    await testDb.insert(SchemaConstants.tableMemories, {
      SchemaConstants.colId: 'mem-1',
      SchemaConstants.colImagePath: '/mock/mem1.jpg',
      SchemaConstants.colThumbnailPath: '/mock/mem1_thumb.jpg',
      SchemaConstants.colCapturedAt: now,
      SchemaConstants.colCreatedAt: now,
      SchemaConstants.colLocationLabel: 'Office',
      SchemaConstants.colIndexingStatus: 'completed',
    });
    await testDb.insert(SchemaConstants.tableMemories, {
      SchemaConstants.colId: 'mem-2',
      SchemaConstants.colImagePath: '/mock/mem2.jpg',
      SchemaConstants.colThumbnailPath: '/mock/mem2_thumb.jpg',
      SchemaConstants.colCapturedAt: now,
      SchemaConstants.colCreatedAt: now,
      SchemaConstants.colLocationLabel: 'Bedroom',
      SchemaConstants.colIndexingStatus: 'completed',
    });
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SearchFeedbackRepository', () {
    test('initially returns zero ranking adjustment when no feedback exists', () async {
      final adjustment = await repository.getRankingAdjustment('mem-1', 'black charger');
      expect(adjustment, 0.0);
      final status = await repository.getFeedbackStatus('mem-1', 'black charger');
      expect(status, 0);
    });

    test('positive feedback adds +0.20 boost and updates status to 1', () async {
      await repository.recordFeedback(
        memoryId: 'mem-1',
        query: 'black charger',
        isPositive: true,
      );

      final adjustment = await repository.getRankingAdjustment('mem-1', 'black charger');
      expect(adjustment, 0.20);
      final status = await repository.getFeedbackStatus('mem-1', 'black charger');
      expect(status, 1);
    });

    test('negative feedback applies -0.35 penalty and updates status to -1', () async {
      await repository.recordFeedback(
        memoryId: 'mem-2',
        query: 'keys',
        isPositive: false,
      );

      final adjustment = await repository.getRankingAdjustment('mem-2', 'keys');
      expect(adjustment, -0.35);
      final status = await repository.getFeedbackStatus('mem-2', 'keys');
      expect(status, -1);
    });

    test('updating feedback updates existing record rather than inserting duplicates', () async {
      await repository.recordFeedback(
        memoryId: 'mem-1',
        query: 'backpack',
        isPositive: false,
      );
      expect(await repository.getTotalFeedbackCount(), 1);

      // Change to positive
      await repository.recordFeedback(
        memoryId: 'mem-1',
        query: 'backpack',
        isPositive: true,
      );
      expect(await repository.getTotalFeedbackCount(), 1);
      expect(await repository.getRankingAdjustment('mem-1', 'backpack'), 0.20);
    });

    test('clearAllFeedback removes all recorded preferences', () async {
      await repository.recordFeedback(memoryId: 'mem-1', query: 'q1', isPositive: true);
      await repository.recordFeedback(memoryId: 'mem-2', query: 'q2', isPositive: false);
      expect(await repository.getTotalFeedbackCount(), 2);

      await repository.clearAllFeedback();
      expect(await repository.getTotalFeedbackCount(), 0);
    });
  });
}
