import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../ai/domain/detected_object.dart';
import '../domain/memory_item.dart';

class MemoryRepository {
  final AppDatabase _dbHelper;
  final FileStorageService _storageService;

  MemoryRepository({
    AppDatabase? dbHelper,
    FileStorageService? storageService,
  })  : _dbHelper = dbHelper ?? AppDatabase.instance,
        _storageService = storageService ?? FileStorageService.instance;

  Future<void> insertMemory(MemoryItem memory) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        SchemaConstants.tableMemories,
        memory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final obj in memory.detectedObjects) {
        await txn.insert(
          SchemaConstants.tableDetectedObjects,
          obj.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateMemoryStatus(String id, MemoryIndexingStatus status, {String? errorMessage}) async {
    final db = await _dbHelper.database;
    await db.update(
      SchemaConstants.tableMemories,
      {
        SchemaConstants.colIndexingStatus: status.name,
        SchemaConstants.colErrorMessage: errorMessage,
      },
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMemoryDetails({
    required String id,
    required String locationLabel,
    String? notes,
    required DateTime capturedAt,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      SchemaConstants.tableMemories,
      {
        SchemaConstants.colLocationLabel: locationLabel,
        SchemaConstants.colNotes: notes,
        SchemaConstants.colCapturedAt: capturedAt.toIso8601String(),
      },
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveDetectedObjects(String memoryId, List<DetectedObject> objects) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        SchemaConstants.tableDetectedObjects,
        where: '${SchemaConstants.colMemoryId} = ?',
        whereArgs: [memoryId],
      );

      for (final obj in objects) {
        await txn.insert(
          SchemaConstants.tableDetectedObjects,
          obj.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<MemoryItem?> getMemoryById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      SchemaConstants.tableMemories,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final objectsData = await db.query(
      SchemaConstants.tableDetectedObjects,
      where: '${SchemaConstants.colMemoryId} = ?',
      whereArgs: [id],
    );

    final objects = objectsData.map((e) => DetectedObject.fromMap(e)).toList();
    return MemoryItem.fromMap(results.first, objects: objects);
  }

  Future<List<MemoryItem>> getAllMemories({int limit = 50, int offset = 0, String? locationFilter}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (locationFilter != null && locationFilter.isNotEmpty) {
      where = '${SchemaConstants.colLocationLabel} = ?';
      whereArgs = [locationFilter];
    }

    final results = await db.query(
      SchemaConstants.tableMemories,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${SchemaConstants.colCapturedAt} DESC',
      limit: limit,
      offset: offset,
    );

    final List<MemoryItem> memories = [];
    for (final map in results) {
      final id = map[SchemaConstants.colId] as String;
      final objectsData = await db.query(
        SchemaConstants.tableDetectedObjects,
        where: '${SchemaConstants.colMemoryId} = ?',
        whereArgs: [id],
      );
      final objects = objectsData.map((e) => DetectedObject.fromMap(e)).toList();
      memories.add(MemoryItem.fromMap(map, objects: objects));
    }

    return memories;
  }

  Future<List<MemoryItem>> getRecentMemories({int limit = 8}) async {
    return getAllMemories(limit: limit, offset: 0);
  }

  Future<int> getMemoryCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${SchemaConstants.tableMemories}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getIndexedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${SchemaConstants.tableMemories} WHERE ${SchemaConstants.colIndexingStatus} = ?',
      ['completed'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedIndexingCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${SchemaConstants.tableMemories} WHERE ${SchemaConstants.colIndexingStatus} = ?',
      ['failed'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<MemoryItem>> getFailedMemories() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      SchemaConstants.tableMemories,
      where: '${SchemaConstants.colIndexingStatus} = ?',
      whereArgs: ['failed'],
    );

    return results.map((m) => MemoryItem.fromMap(m)).toList();
  }

  Future<void> deleteMemory(String id) async {
    final memory = await getMemoryById(id);
    if (memory == null) return;

    final db = await _dbHelper.database;
    await db.delete(
      SchemaConstants.tableMemories,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
    );

    // Clean up files
    await _storageService.deleteFiles(
      originalPath: memory.imagePath,
      thumbnailPath: memory.thumbnailPath,
    );
  }

  /// Get adjacent memories in the same room/location (timeline context)
  Future<Map<String, MemoryItem?>> getAdjacentMemories({
    required String memoryId,
    required String locationLabel,
    required DateTime capturedAt,
  }) async {
    final db = await _dbHelper.database;

    // Previous in location
    final prevResult = await db.query(
      SchemaConstants.tableMemories,
      where: '${SchemaConstants.colLocationLabel} = ? AND ${SchemaConstants.colCapturedAt} < ? AND ${SchemaConstants.colId} != ?',
      whereArgs: [locationLabel, capturedAt.toIso8601String(), memoryId],
      orderBy: '${SchemaConstants.colCapturedAt} DESC',
      limit: 1,
    );

    // Next in location
    final nextResult = await db.query(
      SchemaConstants.tableMemories,
      where: '${SchemaConstants.colLocationLabel} = ? AND ${SchemaConstants.colCapturedAt} > ? AND ${SchemaConstants.colId} != ?',
      whereArgs: [locationLabel, capturedAt.toIso8601String(), memoryId],
      orderBy: '${SchemaConstants.colCapturedAt} ASC',
      limit: 1,
    );

    return {
      'previous': prevResult.isNotEmpty ? MemoryItem.fromMap(prevResult.first) : null,
      'next': nextResult.isNotEmpty ? MemoryItem.fromMap(nextResult.first) : null,
    };
  }
}
