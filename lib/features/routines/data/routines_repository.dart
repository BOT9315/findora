import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../domain/routine_model.dart';

class RoutinesRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  RoutinesRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetches all routines with item count and verified item count, optionally filtered by category
  Future<List<Routine>> getAllRoutines({String? category}) async {
    final db = await _db.database;

    // Seed defaults if empty
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${SchemaConstants.tableRoutines}');
    final count = (countRes.first['cnt'] as int?) ?? 0;
    if (count == 0) {
      await _seedDefaultRoutines();
    }

    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      whereClause = 'WHERE LOWER(r.${SchemaConstants.colRoutineCategory}) = ?';
      whereArgs = [category.toLowerCase()];
    }

    // Query routines joined with aggregated counts
    final results = await db.rawQuery('''
      SELECT 
        r.*,
        COUNT(ri.id) as total_items,
        SUM(CASE WHEN ri.${SchemaConstants.colIsVerifiedPacked} = 1 THEN 1 ELSE 0 END) as verified_items
      FROM ${SchemaConstants.tableRoutines} r
      LEFT JOIN ${SchemaConstants.tableRoutineItems} ri ON r.${SchemaConstants.colId} = ri.${SchemaConstants.colRoutineId}
      $whereClause
      GROUP BY r.${SchemaConstants.colId}
      ORDER BY r.${SchemaConstants.colCreatedAt} DESC
    ''', whereArgs);

    return results.map((row) {
      final total = (row['total_items'] as int?) ?? 0;
      final verified = (row['verified_items'] as int?) ?? 0;
      return Routine.fromMap(row, total: total, verified: verified);
    }).toList();
  }

  /// Fetches a single routine by ID
  Future<Routine?> getRoutineById(String id) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT 
        r.*,
        COUNT(ri.id) as total_items,
        SUM(CASE WHEN ri.${SchemaConstants.colIsVerifiedPacked} = 1 THEN 1 ELSE 0 END) as verified_items
      FROM ${SchemaConstants.tableRoutines} r
      LEFT JOIN ${SchemaConstants.tableRoutineItems} ri ON r.${SchemaConstants.colId} = ri.${SchemaConstants.colRoutineId}
      WHERE r.${SchemaConstants.colId} = ?
      GROUP BY r.${SchemaConstants.colId}
    ''', [id]);

    if (results.isEmpty) return null;
    final row = results.first;
    final total = (row['total_items'] as int?) ?? 0;
    final verified = (row['verified_items'] as int?) ?? 0;
    return Routine.fromMap(row, total: total, verified: verified);
  }

  /// Fetches all items in a routine with their latest historical sighting and verification status
  Future<List<RoutineItemDetail>> getRoutineItems(String routineId) async {
    final db = await _db.database;

    final results = await db.rawQuery('''
      SELECT 
        ri.${SchemaConstants.colId} as routine_item_id,
        ri.${SchemaConstants.colRoutineId} as routine_id,
        ri.${SchemaConstants.colItemId} as item_id,
        ri.${SchemaConstants.colIsVerifiedPacked} as is_verified_packed,
        ri.${SchemaConstants.colLastVerifiedAt} as last_verified_at,
        ii.${SchemaConstants.colName} as item_name,
        ii.${SchemaConstants.colCategory} as item_category,
        ii.${SchemaConstants.colReferencePhotoPath} as item_reference_photo_path,
        ii.${SchemaConstants.colLastObservedLocation} as last_observed_location,
        ii.${SchemaConstants.colLastObservedAt} as last_observed_at,
        ii.${SchemaConstants.colLastObservedMemoryId} as last_observed_memory_id,
        m.${SchemaConstants.colThumbnailPath} as last_observed_thumbnail_path
      FROM ${SchemaConstants.tableRoutineItems} ri
      JOIN ${SchemaConstants.tableItemIdentities} ii ON ri.${SchemaConstants.colItemId} = ii.${SchemaConstants.colId}
      LEFT JOIN ${SchemaConstants.tableMemories} m ON ii.${SchemaConstants.colLastObservedMemoryId} = m.${SchemaConstants.colId}
      WHERE ri.${SchemaConstants.colRoutineId} = ?
      ORDER BY ri.${SchemaConstants.colIsVerifiedPacked} ASC, ii.${SchemaConstants.colName} ASC
    ''', [routineId]);

    return results.map((row) {
      return RoutineItemDetail(
        routineItemId: row['routine_item_id'] as String,
        routineId: row['routine_id'] as String,
        itemId: row['item_id'] as String,
        itemName: row['item_name'] as String,
        itemCategory: row['item_category'] as String,
        itemReferencePhotoPath: row['item_reference_photo_path'] as String?,
        isVerifiedPacked: (row['is_verified_packed'] as int? ?? 0) == 1,
        lastVerifiedAt: row['last_verified_at'] != null
            ? DateTime.tryParse(row['last_verified_at'] as String)
            : null,
        lastObservedLocation: row['last_observed_location'] as String?,
        lastObservedAt: row['last_observed_at'] != null
            ? DateTime.tryParse(row['last_observed_at'] as String)
            : null,
        lastObservedMemoryId: row['last_observed_memory_id'] as String?,
        lastObservedThumbnailPath: row['last_observed_thumbnail_path'] as String?,
      );
    }).toList();
  }

  /// Creates a new user routine
  Future<Routine> createRoutine({
    required String name,
    required String iconName,
    String category = 'general',
    String? scheduledTime,
    bool isReminderEnabled = false,
    String? description,
  }) async {
    final db = await _db.database;
    final routine = Routine(
      id: _uuid.v4(),
      name: name,
      iconName: iconName,
      category: category,
      scheduledTime: scheduledTime,
      isReminderEnabled: isReminderEnabled,
      description: description,
      createdAt: DateTime.now(),
    );
    await db.insert(SchemaConstants.tableRoutines, routine.toMap());
    return routine;
  }

  /// Updates an existing routine
  Future<void> updateRoutine(Routine routine) async {
    final db = await _db.database;
    await db.update(
      SchemaConstants.tableRoutines,
      routine.toMap(),
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [routine.id],
    );
  }

  /// Deletes a routine and its checklist item references
  Future<void> deleteRoutine(String routineId) async {
    final db = await _db.database;
    await db.delete(
      SchemaConstants.tableRoutines,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [routineId],
    );
  }

  /// Adds an item to a routine checklist
  Future<String> addItemToRoutine(String routineId, String itemId) async {
    final db = await _db.database;
    final id = _uuid.v4();
    await db.insert(SchemaConstants.tableRoutineItems, {
      SchemaConstants.colId: id,
      SchemaConstants.colRoutineId: routineId,
      SchemaConstants.colItemId: itemId,
      SchemaConstants.colIsVerifiedPacked: 0,
      SchemaConstants.colLastVerifiedAt: null,
    });
    return id;
  }

  /// Removes an item from a routine
  Future<void> removeItemFromRoutine(String routineItemId) async {
    final db = await _db.database;
    await db.delete(
      SchemaConstants.tableRoutineItems,
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [routineItemId],
    );
  }

  /// Updates user verification state for a routine item
  Future<void> setItemVerifiedPacked(String routineItemId, bool isPacked) async {
    final db = await _db.database;
    await db.update(
      SchemaConstants.tableRoutineItems,
      {
        SchemaConstants.colIsVerifiedPacked: isPacked ? 1 : 0,
        SchemaConstants.colLastVerifiedAt: isPacked ? DateTime.now().toIso8601String() : null,
      },
      where: '${SchemaConstants.colId} = ?',
      whereArgs: [routineItemId],
    );
  }

  /// Resets all checklist items to unverified for a routine
  Future<void> resetAllVerifications(String routineId) async {
    final db = await _db.database;
    await db.update(
      SchemaConstants.tableRoutineItems,
      {
        SchemaConstants.colIsVerifiedPacked: 0,
        SchemaConstants.colLastVerifiedAt: null,
      },
      where: '${SchemaConstants.colRoutineId} = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> _seedDefaultRoutines() async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(SchemaConstants.tableRoutines, {
      SchemaConstants.colId: _uuid.v4(),
      SchemaConstants.colName: 'College Prep',
      SchemaConstants.colIconName: 'school',
      SchemaConstants.colRoutineCategory: 'college',
      SchemaConstants.colScheduledTime: '08:00 AM',
      SchemaConstants.colIsReminderEnabled: 1,
      SchemaConstants.colDescription: 'ID card, notebook, laptop, and chargers before morning lectures',
      SchemaConstants.colCreatedAt: now,
    });

    await db.insert(SchemaConstants.tableRoutines, {
      SchemaConstants.colId: _uuid.v4(),
      SchemaConstants.colName: 'Daily Commute',
      SchemaConstants.colIconName: 'business_center',
      SchemaConstants.colRoutineCategory: 'office',
      SchemaConstants.colScheduledTime: '09:15 AM',
      SchemaConstants.colIsReminderEnabled: 1,
      SchemaConstants.colDescription: 'Keys, wallet, badge, and office access tokens',
      SchemaConstants.colCreatedAt: now,
    });

    await db.insert(SchemaConstants.tableRoutines, {
      SchemaConstants.colId: _uuid.v4(),
      SchemaConstants.colName: 'Gym Session',
      SchemaConstants.colIconName: 'fitness_center',
      SchemaConstants.colRoutineCategory: 'gym',
      SchemaConstants.colScheduledTime: '06:30 PM',
      SchemaConstants.colIsReminderEnabled: 1,
      SchemaConstants.colDescription: 'Water bottle, gym strap, headphones, and towel',
      SchemaConstants.colCreatedAt: now,
    });

    await db.insert(SchemaConstants.tableRoutines, {
      SchemaConstants.colId: _uuid.v4(),
      SchemaConstants.colName: 'Weekend Travel',
      SchemaConstants.colIconName: 'flight_takeoff',
      SchemaConstants.colRoutineCategory: 'travel',
      SchemaConstants.colScheduledTime: '07:00 AM',
      SchemaConstants.colIsReminderEnabled: 1,
      SchemaConstants.colDescription: 'Passport, toiletry kit, power bank, and jackets',
      SchemaConstants.colCreatedAt: now,
    });
  }
}
