import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/offline/services/offline_capability_service.dart';

void main() {
  late Database testDb;

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
  });

  tearDown(() async {
    await testDb.close();
  });

  group('OfflineCapabilityService', () {
    test('runOfflineAudit produces complete diagnostic report and verifies air-gapped security', () async {
      final service = OfflineCapabilityService.instance;
      final report = await service.runOfflineAudit();

      expect(report, isNotNull);
      expect(report.checks.length, 5);

      // Verify Local Database check
      final dbCheck = report.checks.firstWhere((c) => c.title.contains('Database'));
      expect(dbCheck.isPassed, isTrue);

      // Verify Zero Cloud Outbound / Air Gap
      final airGapCheck = report.checks.firstWhere((c) => c.title.contains('Air-Gap'));
      expect(airGapCheck.isPassed, isTrue);

      // Verify On-Device AI
      final aiCheck = report.checks.firstWhere((c) => c.title.contains('On-Device AI'));
      expect(aiCheck.isPassed, isTrue);
    });
  });
}
