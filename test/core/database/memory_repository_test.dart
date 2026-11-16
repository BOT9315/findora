// Unit tests for MemoryRepository using an in-memory SQLite database.
// Uses sqflite_common_ffi to run without a real device.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/memories/data/memory_repository.dart';
import 'package:find_my_stuff_ai/features/memories/domain/memory_item.dart';

void main() {
  late MemoryRepository repository;
  late Database testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Open a fresh in-memory database for each test
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
  });

  tearDown(() async {
    await testDb.close();
  });

  group('MemoryRepository CRUD', () {
    test('insertMemory stores a record and it can be retrieved', () async {
      final memory = MemoryItem(
        id: 'test-id-001',
        imagePath: '/tmp/test.jpg',
        thumbnailPath: '/tmp/test_thumb.jpg',
        capturedAt: DateTime(2026, 1, 15, 10, 30),
        createdAt: DateTime(2026, 1, 15, 10, 30, 5),
        locationLabel: 'Study Desk',
        notes: 'Testing insertion',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );

      await repository.insertMemory(memory);

      final retrieved = await repository.getMemoryById('test-id-001');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-id-001'));
      expect(retrieved.locationLabel, equals('Study Desk'));
      expect(retrieved.notes, equals('Testing insertion'));
    });

    test('getAllMemories returns inserted records in descending time order', () async {
      final now = DateTime.now();
      final m1 = MemoryItem(
        id: 'mem-001',
        imagePath: '/tmp/a.jpg',
        thumbnailPath: '/tmp/a_thumb.jpg',
        capturedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        locationLabel: 'Bedroom',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );
      final m2 = MemoryItem(
        id: 'mem-002',
        imagePath: '/tmp/b.jpg',
        thumbnailPath: '/tmp/b_thumb.jpg',
        capturedAt: now,
        createdAt: now,
        locationLabel: 'Kitchen',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );

      await repository.insertMemory(m1);
      await repository.insertMemory(m2);

      final all = await repository.getAllMemories();
      expect(all.length, equals(2));
      // Most recent first
      expect(all.first.id, equals('mem-002'));
    });

    test('updateMemoryDetails persists changes', () async {
      final memory = MemoryItem(
        id: 'upd-001',
        imagePath: '/tmp/x.jpg',
        thumbnailPath: '/tmp/x_thumb.jpg',
        capturedAt: DateTime(2026, 1, 1, 12, 0),
        createdAt: DateTime.now(),
        locationLabel: 'Hallway',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );
      await repository.insertMemory(memory);

      final newTime = DateTime(2026, 1, 2, 14, 0);
      await repository.updateMemoryDetails(
        id: 'upd-001',
        locationLabel: 'Living Room',
        notes: 'Updated note',
        capturedAt: newTime,
      );

      final retrieved = await repository.getMemoryById('upd-001');
      expect(retrieved!.locationLabel, equals('Living Room'));
      expect(retrieved.notes, equals('Updated note'));
      expect(retrieved.capturedAt, equals(newTime));
    });

    test('updateMemoryStatus updates indexing status', () async {
      final memory = MemoryItem(
        id: 'status-001',
        imagePath: '/tmp/s.jpg',
        thumbnailPath: '/tmp/s_thumb.jpg',
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        locationLabel: 'Desk',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );
      await repository.insertMemory(memory);

      await repository.updateMemoryStatus('status-001', MemoryIndexingStatus.completed);

      final retrieved = await repository.getMemoryById('status-001');
      expect(retrieved!.indexingStatus, equals(MemoryIndexingStatus.completed));
    });

    test('deleteMemory removes the record from database', () async {
      final memory = MemoryItem(
        id: 'del-001',
        imagePath: '/tmp/del.jpg',
        thumbnailPath: '/tmp/del_thumb.jpg',
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        locationLabel: 'Office',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      );
      await repository.insertMemory(memory);

      var retrieved = await repository.getMemoryById('del-001');
      expect(retrieved, isNotNull);

      await repository.deleteMemory('del-001');

      retrieved = await repository.getMemoryById('del-001');
      expect(retrieved, isNull);
    });

    test('getMemoryCount returns accurate count', () async {
      final count0 = await repository.getMemoryCount();
      expect(count0, equals(0));

      await repository.insertMemory(MemoryItem(
        id: 'cnt-001',
        imagePath: '/tmp/c1.jpg',
        thumbnailPath: '/tmp/c1_thumb.jpg',
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        locationLabel: 'Office',
        indexingStatus: MemoryIndexingStatus.pending,
        detectedObjects: [],
      ));

      final count1 = await repository.getMemoryCount();
      expect(count1, equals(1));
    });

    test('getAllMemories filters by location', () async {
      final now = DateTime.now();
      await repository.insertMemory(MemoryItem(
        id: 'filter-001',
        imagePath: '/tmp/f1.jpg',
        thumbnailPath: '/tmp/f1_thumb.jpg',
        capturedAt: now,
        createdAt: now,
        locationLabel: 'Study Desk',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: [],
      ));
      await repository.insertMemory(MemoryItem(
        id: 'filter-002',
        imagePath: '/tmp/f2.jpg',
        thumbnailPath: '/tmp/f2_thumb.jpg',
        capturedAt: now,
        createdAt: now,
        locationLabel: 'Kitchen',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: [],
      ));

      final deskResults = await repository.getAllMemories(locationFilter: 'Study Desk');
      expect(deskResults.length, equals(1));
      expect(deskResults.first.id, equals('filter-001'));

      final kitchenResults = await repository.getAllMemories(locationFilter: 'Kitchen');
      expect(kitchenResults.length, equals(1));
      expect(kitchenResults.first.id, equals('filter-002'));
    });
  });
}
