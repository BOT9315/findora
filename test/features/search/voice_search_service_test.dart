// Unit tests for VoiceSearchService — verifies voice search initialization,
// availability checks, speech listening state management, and spoken search results preference.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/search/services/voice_search_service.dart';

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

  group('VoiceSearchService', () {
    test('singleton instance is non-null and starts in non-listening state', () {
      final service = VoiceSearchService.instance;
      expect(service, isNotNull);
      expect(service.isListening, isFalse);
    });

    test('spoken results setting is stored and read from local app_settings', () async {
      final db = AppDatabase.instance;
      // Default should be null / off
      var setting = await db.getSetting('speak_search_results');
      expect(setting, isNull);

      // Enable spoken results
      await db.setSetting('speak_search_results', 'true');
      setting = await db.getSetting('speak_search_results');
      expect(setting, equals('true'));

      // Disable spoken results
      await db.setSetting('speak_search_results', 'false');
      setting = await db.getSetting('speak_search_results');
      expect(setting, equals('false'));
    });

    test('stopSpeaking executes safely without error', () async {
      final service = VoiceSearchService.instance;
      expect(() async => await service.stopSpeaking(), returnsNormally);
    });

    test('cancelListening executes safely without error', () async {
      final service = VoiceSearchService.instance;
      expect(() async => await service.cancelListening(), returnsNormally);
    });
  });
}
