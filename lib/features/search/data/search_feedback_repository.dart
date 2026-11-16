import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';

class SearchFeedbackRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  SearchFeedbackRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Records or updates user feedback for a specific memory result on a query
  Future<void> recordFeedback({
    required String memoryId,
    required String query,
    required bool isPositive,
  }) async {
    final db = await _db.database;
    final normalizedQuery = query.trim().toLowerCase();

    // Check if feedback already exists for this memory and query
    final existing = await db.query(
      SchemaConstants.tableSearchFeedback,
      where: '${SchemaConstants.colMemoryId} = ? AND query = ?',
      whereArgs: [memoryId, normalizedQuery],
    );

    if (existing.isNotEmpty) {
      await db.update(
        SchemaConstants.tableSearchFeedback,
        {
          'is_positive': isPositive ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        where: '${SchemaConstants.colMemoryId} = ? AND query = ?',
        whereArgs: [memoryId, normalizedQuery],
      );
    } else {
      await db.insert(SchemaConstants.tableSearchFeedback, {
        SchemaConstants.colId: _uuid.v4(),
        SchemaConstants.colMemoryId: memoryId,
        'query': normalizedQuery,
        'is_positive': isPositive ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Gets the feedback record for a memory and query: 1 for thumbs up, -1 for thumbs down, 0 for none
  Future<int> getFeedbackStatus(String memoryId, String query) async {
    final db = await _db.database;
    final normalizedQuery = query.trim().toLowerCase();

    final results = await db.query(
      SchemaConstants.tableSearchFeedback,
      where: '${SchemaConstants.colMemoryId} = ? AND (query = ? OR query = \'\')',
      whereArgs: [memoryId, normalizedQuery],
    );

    if (results.isEmpty) return 0;
    final isPos = (results.first['is_positive'] as int? ?? 0) == 1;
    return isPos ? 1 : -1;
  }

  /// Calculates transparent score adjustment (-0.35 to +0.20) for personalized ranking
  Future<double> getRankingAdjustment(String memoryId, String query) async {
    final status = await getFeedbackStatus(memoryId, query);
    if (status == 1) return 0.20; // User confirmed match
    if (status == -1) return -0.35; // User rejected match
    return 0.0;
  }

  /// Gets total feedback count
  Future<int> getTotalFeedbackCount() async {
    final db = await _db.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${SchemaConstants.tableSearchFeedback}');
    return (res.first['cnt'] as int?) ?? 0;
  }

  /// Clears all feedback records
  Future<void> clearAllFeedback() async {
    final db = await _db.database;
    await db.delete(SchemaConstants.tableSearchFeedback);
  }
}
