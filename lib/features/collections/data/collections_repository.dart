import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../../memories/domain/memory_item.dart';
import '../domain/location_collection.dart';

class CollectionsRepository {
  final AppDatabase _dbHelper;
  final _uuid = const Uuid();

  CollectionsRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<void> initializeDefaultCollections() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${SchemaConstants.tableCollections}'),
    );

    if (count == 0) {
      final batch = db.batch();
      for (final loc in AppConstants.defaultLocations) {
        final id = _uuid.v4();
        String icon = 'room';
        if (loc.contains('Backpack')) icon = 'backpack';
        if (loc.contains('Desk')) icon = 'desk';
        if (loc.contains('Kitchen')) icon = 'kitchen';
        if (loc.contains('Living')) icon = 'couch';
        if (loc.contains('Car')) icon = 'car';

        batch.insert(SchemaConstants.tableCollections, {
          SchemaConstants.colId: id,
          SchemaConstants.colName: loc,
          SchemaConstants.colIconName: icon,
          SchemaConstants.colDescription: 'Observations in $loc',
          SchemaConstants.colCreatedAt: DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<LocationCollection>> getCollectionsWithCounts() async {
    final db = await _dbHelper.database;
    await initializeDefaultCollections();

    final query = '''
      SELECT c.*, 
        (SELECT COUNT(*) FROM ${SchemaConstants.tableMemories} m 
         WHERE LOWER(m.${SchemaConstants.colLocationLabel}) = LOWER(c.${SchemaConstants.colName})
         OR m.${SchemaConstants.colId} IN (
            SELECT ${SchemaConstants.colMemoryId} FROM ${SchemaConstants.tableCollectionMemberships} cm 
            WHERE cm.${SchemaConstants.colCollectionId} = c.${SchemaConstants.colId}
         )
        ) as memory_count
      FROM ${SchemaConstants.tableCollections} c
      ORDER BY memory_count DESC, c.${SchemaConstants.colName} ASC;
    ''';

    final results = await db.rawQuery(query);
    return results.map((row) {
      final count = (row['memory_count'] as num?)?.toInt() ?? 0;
      return LocationCollection.fromMap(row, count: count);
    }).toList();
  }

  Future<void> createCollection(String name, String iconName, {String? description}) async {
    final db = await _dbHelper.database;
    final id = _uuid.v4();
    await db.insert(
      SchemaConstants.tableCollections,
      {
        SchemaConstants.colId: id,
        SchemaConstants.colName: name.trim(),
        SchemaConstants.colIconName: iconName,
        SchemaConstants.colDescription: description?.trim(),
        SchemaConstants.colCreatedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCollection(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      SchemaConstants.tableCollections,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<List<MemoryItem>> getMemoriesForCollection(String collectionId, String collectionName) async {
    final db = await _dbHelper.database;

    final query = '''
      SELECT DISTINCT m.* FROM ${SchemaConstants.tableMemories} m
      LEFT JOIN ${SchemaConstants.tableCollectionMemberships} cm ON m.${SchemaConstants.colId} = cm.${SchemaConstants.colMemoryId}
      WHERE LOWER(m.${SchemaConstants.colLocationLabel}) = LOWER(?) OR cm.${SchemaConstants.colCollectionId} = ?
      ORDER BY m.${SchemaConstants.colCapturedAt} DESC;
    ''';

    final results = await db.rawQuery(query, [collectionName, collectionId]);
    return results.map((m) => MemoryItem.fromMap(m)).toList();
  }
}
