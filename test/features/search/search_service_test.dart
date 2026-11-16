// Unit and integration tests for SearchService — verifies natural language search,
// ranking calculation, metadata and attribute matching, and time filtering.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/ai/domain/detected_object.dart';
import 'package:find_my_stuff_ai/features/memories/data/memory_repository.dart';
import 'package:find_my_stuff_ai/features/memories/domain/memory_item.dart';
import 'package:find_my_stuff_ai/features/search/data/search_service.dart';
import 'package:find_my_stuff_ai/features/search/domain/search_query_model.dart';

void main() {
  late MemoryRepository repository;
  late SearchService searchService;
  late Database testDb;

  setUpAll(() {
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
    repository = MemoryRepository();
    searchService = SearchService(memoryRepository: repository);
  });

  tearDown(() async {
    await testDb.close();
  });

  group('SearchService', () {
    test('returns empty results when database has no memories', () async {
      final results = await searchService.search('black charger');
      expect(results, isEmpty);
    });

    test('matches recognized object and places it at the top of results', () async {
      final now = DateTime.now();

      // Memory 1: Contains a black charger object
      final m1 = MemoryItem(
        id: 'mem-charger',
        imagePath: '/path/charger.jpg',
        thumbnailPath: '/path/charger_thumb.jpg',
        capturedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now,
        locationLabel: 'Study Desk',
        notes: 'Workspace photo',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-1',
            memoryId: 'mem-charger',
            label: 'Charger',
            confidence: 0.92,
            attributes: {'color': 'black', 'material': 'plastic'},
            boundingBox: BoundingBox(left: 0.2, top: 0.3, width: 0.4, height: 0.5),
          ),
        ],
      );

      // Memory 2: Contains keys, no charger
      final m2 = MemoryItem(
        id: 'mem-keys',
        imagePath: '/path/keys.jpg',
        thumbnailPath: '/path/keys_thumb.jpg',
        capturedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        locationLabel: 'Entryway Shelf',
        notes: 'Doorway table',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-2',
            memoryId: 'mem-keys',
            label: 'Keys',
            confidence: 0.88,
            attributes: {'color': 'silver', 'material': 'metal'},
            boundingBox: BoundingBox(left: 0.1, top: 0.1, width: 0.3, height: 0.3),
          ),
        ],
      );

      await repository.insertMemory(m1);
      await repository.insertMemory(m2);

      final results = await searchService.search('find my black charger');
      expect(results, isNotEmpty);
      expect(results.first.memory.id, equals('mem-charger'));
      expect(results.first.matchedObject?.label, equals('Charger'));
      expect(results.first.matchedHighlights.any((h) => h.contains('Charger')), isTrue);
    });

    test('respects time filter', () async {
      final now = DateTime.now();

      // Memory from yesterday
      final mYesterday = MemoryItem(
        id: 'mem-yest',
        imagePath: '/path/yest.jpg',
        thumbnailPath: '/path/yest_thumb.jpg',
        capturedAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        locationLabel: 'Study Desk',
        notes: 'Desk yesterday',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-y',
            memoryId: 'mem-yest',
            label: 'Charger',
            confidence: 0.9,
          ),
        ],
      );

      // Memory from 20 days ago
      final mOld = MemoryItem(
        id: 'mem-old',
        imagePath: '/path/old.jpg',
        thumbnailPath: '/path/old_thumb.jpg',
        capturedAt: now.subtract(const Duration(days: 20)),
        createdAt: now,
        locationLabel: 'Study Desk',
        notes: 'Desk long ago',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-o',
            memoryId: 'mem-old',
            label: 'Charger',
            confidence: 0.9,
          ),
        ],
      );

      await repository.insertMemory(mYesterday);
      await repository.insertMemory(mOld);

      final results = await searchService.search(
        'charger',
        timeOverride: TimeFilter.yesterday,
      );

      // Should only match the memory from yesterday
      expect(results.any((r) => r.memory.id == 'mem-yest'), isTrue);
      expect(results.any((r) => r.memory.id == 'mem-old'), isFalse);
    });
  });
}
