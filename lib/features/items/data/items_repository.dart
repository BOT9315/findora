import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../domain/item_identity.dart';
import '../domain/item_observation.dart';

class ItemsRepository {
  final AppDatabase _dbHelper;
  final _uuid = const Uuid();

  ItemsRepository({AppDatabase? dbHelper}) : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<void> saveItem(ItemIdentity item) async {
    final db = await _dbHelper.database;
    await db.insert(
      SchemaConstants.tableItemIdentities,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ItemIdentity?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      SchemaConstants.tableItemIdentities,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ItemIdentity.fromMap(results.first);
  }

  Future<List<ItemIdentity>> getAllItems() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      SchemaConstants.tableItemIdentities,
      orderBy: '${SchemaConstants.colLastObservedAt} DESC',
    );
    return results.map((e) => ItemIdentity.fromMap(e)).toList();
  }

  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      SchemaConstants.tableItemIdentities,
      {SchemaConstants.colStatus: status.name},
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> updateItemLastObserved({
    required String itemId,
    required String memoryId,
    required DateTime observedAt,
    required String location,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      SchemaConstants.tableItemIdentities,
      {
        SchemaConstants.colLastObservedMemoryId: memoryId,
        SchemaConstants.colLastObservedAt: observedAt.toIso8601String(),
        SchemaConstants.colLastObservedLocation: location,
        SchemaConstants.colStatus: ItemStatus.lastObserved.name,
      },
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> recordObservation(ItemObservation obs) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert(
        SchemaConstants.tableItemObservations,
        obs.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If observation is newer than current item last observation, update item
      final itemResults = await txn.query(
        SchemaConstants.tableItemIdentities,
        where: '${SchemaConstants.colId} = ?',
        whereArgs: [obs.itemId],
        limit: 1,
      );

      if (itemResults.isNotEmpty) {
        final current = ItemIdentity.fromMap(itemResults.first);
        if (current.lastObservedAt == null || obs.observedAt.isAfter(current.lastObservedAt!)) {
          await txn.update(
            SchemaConstants.tableItemIdentities,
            {
              SchemaConstants.colLastObservedMemoryId: obs.memoryId,
              SchemaConstants.colLastObservedAt: obs.observedAt.toIso8601String(),
              SchemaConstants.colLastObservedLocation: obs.locationLabel,
            },
            where: '${SchemaConstants.colId} = ?',
            whereArgs: [obs.itemId],
          );
        }
      }
    });
  }

  Future<List<ItemObservation>> getObservationsForItem(String itemId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      SchemaConstants.tableItemObservations,
      where: '${SchemaConstants.colItemId} = ?',
      whereArgs: [itemId],
      orderBy: '${SchemaConstants.colObservedAt} DESC',
    );
    return results.map((e) => ItemObservation.fromMap(e)).toList();
  }

  Future<void> updateObservationConfirmation(String observationId, ConfirmationStatus confirmation) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        SchemaConstants.tableItemObservations,
        {SchemaConstants.colUserConfirmation: confirmation.name},
        where: '${SchemaConstants.colId} = ?',
        whereArgs: [observationId],
      );

      // Re-evaluate the item's latest confirmed observation
      final obsResult = await txn.query(
        SchemaConstants.tableItemObservations,
        where: '${SchemaConstants.colId} = ?',
        whereArgs: [observationId],
        limit: 1,
      );

      if (obsResult.isNotEmpty) {
        final itemId = obsResult.first[SchemaConstants.colItemId] as String;
        final confirmedObs = await txn.query(
          SchemaConstants.tableItemObservations,
          where: '${SchemaConstants.colItemId} = ? AND ${SchemaConstants.colUserConfirmation} = ?',
          whereArgs: [itemId, ConfirmationStatus.confirmed.name],
          orderBy: '${SchemaConstants.colObservedAt} DESC',
          limit: 1,
        );

        if (confirmedObs.isNotEmpty) {
          final latest = confirmedObs.first;
          final overrideLoc = latest[SchemaConstants.colManualLocationOverride] as String?;
          final effectiveLoc = (overrideLoc != null && overrideLoc.trim().isNotEmpty)
              ? overrideLoc
              : latest[SchemaConstants.colLocationLabel];
          await txn.update(
            SchemaConstants.tableItemIdentities,
            {
              SchemaConstants.colLastObservedMemoryId: latest[SchemaConstants.colMemoryId],
              SchemaConstants.colLastObservedAt: latest[SchemaConstants.colObservedAt],
              SchemaConstants.colLastObservedLocation: effectiveLoc,
              SchemaConstants.colStatus: ItemStatus.foundAndConfirmed.name,
            },
            where: '${SchemaConstants.colId} = ?',
            whereArgs: [itemId],
          );
        }
      }
    });
  }

  /// Manually corrects or updates the location label for an observation
  Future<void> updateObservationLocation(String observationId, String newLocation) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        SchemaConstants.tableItemObservations,
        {SchemaConstants.colManualLocationOverride: newLocation.trim()},
        where: '${SchemaConstants.colId} = ?',
        whereArgs: [observationId],
      );

      // Check if this was the latest confirmed observation for the item
      final obsResult = await txn.query(
        SchemaConstants.tableItemObservations,
        where: '${SchemaConstants.colId} = ?',
        whereArgs: [observationId],
        limit: 1,
      );

      if (obsResult.isNotEmpty) {
        final itemId = obsResult.first[SchemaConstants.colItemId] as String;
        final confirmedObs = await txn.query(
          SchemaConstants.tableItemObservations,
          where: '${SchemaConstants.colItemId} = ? AND ${SchemaConstants.colUserConfirmation} = ?',
          whereArgs: [itemId, ConfirmationStatus.confirmed.name],
          orderBy: '${SchemaConstants.colObservedAt} DESC',
          limit: 1,
        );

        if (confirmedObs.isNotEmpty && confirmedObs.first[SchemaConstants.colId] == observationId) {
          await txn.update(
            SchemaConstants.tableItemIdentities,
            {SchemaConstants.colLastObservedLocation: newLocation.trim()},
            where: '${SchemaConstants.colId} = ?',
            whereArgs: [itemId],
          );
        }
      }
    });
  }

  /// Scans memories for potential matches for an existing item without automatically merging them
  Future<List<ItemObservation>> scanForPotentialMatches(String itemId) async {
    final db = await _dbHelper.database;
    final item = await getItemById(itemId);
    if (item == null) return [];

    // Find candidate detected objects matching item's category or name keywords
    final objects = await db.rawQuery('''
      SELECT d.*, m.${SchemaConstants.colLocationLabel}, m.${SchemaConstants.colCapturedAt}
      FROM ${SchemaConstants.tableDetectedObjects} d
      JOIN ${SchemaConstants.tableMemories} m ON d.${SchemaConstants.colMemoryId} = m.${SchemaConstants.colId}
      WHERE LOWER(d.${SchemaConstants.colLabel}) = LOWER(?)
         OR LOWER(?) LIKE '%' || LOWER(d.${SchemaConstants.colLabel}) || '%'
    ''', [item.category, item.name]);

    final existingObs = await getObservationsForItem(itemId);
    final existingMemoryIds = existingObs.map((o) => o.memoryId).toSet();

    final List<ItemObservation> newSuggestions = [];
    for (final obj in objects) {
      final memoryId = obj[SchemaConstants.colMemoryId] as String;
      if (existingMemoryIds.contains(memoryId)) continue;

      final obs = ItemObservation(
        id: _uuid.v4(),
        itemId: itemId,
        memoryId: memoryId,
        detectedObjectId: obj[SchemaConstants.colId] as String?,
        observedAt: DateTime.parse(obj[SchemaConstants.colCapturedAt] as String),
        locationLabel: obj[SchemaConstants.colLocationLabel] as String,
        matchConfidence: (obj[SchemaConstants.colConfidence] as num).toDouble(),
        userConfirmation: ConfirmationStatus.pending,
        notes: 'Potential match sighted in ${obj[SchemaConstants.colLocationLabel]}',
      );

      await db.insert(
        SchemaConstants.tableItemObservations,
        obs.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      newSuggestions.add(obs);
      existingMemoryIds.add(memoryId);
    }

    return getObservationsForItem(itemId);
  }

  Future<void> deleteItem(String itemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      SchemaConstants.tableItemIdentities,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [itemId],
    );
  }

  /// Automatically groups or links a newly detected object with known items
  Future<void> autoLinkDetectedObject({
    required String memoryId,
    required String label,
    required String locationLabel,
    required DateTime capturedAt,
    required double confidence,
    String? detectedObjectId,
  }) async {
    final db = await _dbHelper.database;

    // Check if an existing item identity matches label
    final existingItems = await db.query(
      SchemaConstants.tableItemIdentities,
      where: 'LOWER(${SchemaConstants.colCategory}) = LOWER(?) OR LOWER(${SchemaConstants.colName}) LIKE LOWER(?)',
      whereArgs: [label, '%$label%'],
      limit: 1,
    );

    String itemId;
    if (existingItems.isNotEmpty) {
      itemId = existingItems.first[SchemaConstants.colId] as String;
    } else {
      // Create new identity for this item category
      itemId = _uuid.v4();
      final newItem = ItemIdentity(
        id: itemId,
        name: label,
        category: label,
        lastObservedMemoryId: memoryId,
        lastObservedAt: capturedAt,
        lastObservedLocation: locationLabel,
        status: ItemStatus.lastObserved,
        createdAt: DateTime.now(),
      );
      await saveItem(newItem);
    }

    final obs = ItemObservation(
      id: _uuid.v4(),
      itemId: itemId,
      memoryId: memoryId,
      detectedObjectId: detectedObjectId,
      observedAt: capturedAt,
      locationLabel: locationLabel,
      matchConfidence: confidence,
      userConfirmation: ConfirmationStatus.pending,
    );

    await recordObservation(obs);
  }
}
