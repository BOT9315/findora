import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'database_migrations.dart';
import 'schema_constants.dart';

class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Allow injecting custom database instance (e.g. For FFI unit tests)
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, SchemaConstants.databaseName);

    return await openDatabase(
      path,
      version: SchemaConstants.databaseVersion,
      onConfigure: DatabaseMigrations.onConfigure,
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
    );
  }

  // App Settings Helper Methods
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      SchemaConstants.tableAppSettings,
      columns: [SchemaConstants.colValue],
      where: '${SchemaConstants.colKey} = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first[SchemaConstants.colValue] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      SchemaConstants.tableAppSettings,
      {
        SchemaConstants.colKey: key,
        SchemaConstants.colValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeSetting(String key) async {
    final db = await database;
    await db.delete(
      SchemaConstants.tableAppSettings,
      where: '${SchemaConstants.colKey} = ?',
      whereArgs: [key],
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> wipeAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(SchemaConstants.tableCollectionMemberships);
      await txn.delete(SchemaConstants.tableCollections);
      await txn.delete(SchemaConstants.tableItemObservations);
      await txn.delete(SchemaConstants.tableItemIdentities);
      await txn.delete(SchemaConstants.tableDetectedObjects);
      await txn.delete(SchemaConstants.tableEmbeddings);
      await txn.delete(SchemaConstants.tableMemories);
      // Keep app settings like theme & onboarding unless specified
    });
  }
}
