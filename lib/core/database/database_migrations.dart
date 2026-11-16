import 'package:sqflite/sqflite.dart';
import 'schema_constants.dart';

class DatabaseMigrations {
  static Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Memories Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableMemories} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colImagePath} TEXT NOT NULL,
        ${SchemaConstants.colThumbnailPath} TEXT NOT NULL,
        ${SchemaConstants.colCapturedAt} TEXT NOT NULL,
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL,
        ${SchemaConstants.colLocationLabel} TEXT NOT NULL,
        ${SchemaConstants.colNotes} TEXT,
        ${SchemaConstants.colIndexingStatus} TEXT NOT NULL DEFAULT 'pending',
        ${SchemaConstants.colErrorMessage} TEXT
      );
    ''');
    batch.execute('CREATE INDEX idx_memories_captured_at ON ${SchemaConstants.tableMemories}(${SchemaConstants.colCapturedAt});');
    batch.execute('CREATE INDEX idx_memories_location ON ${SchemaConstants.tableMemories}(${SchemaConstants.colLocationLabel});');

    // 2. Detected Objects Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableDetectedObjects} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colMemoryId} TEXT NOT NULL,
        ${SchemaConstants.colLabel} TEXT NOT NULL,
        ${SchemaConstants.colConfidence} REAL NOT NULL,
        ${SchemaConstants.colAttributes} TEXT,
        ${SchemaConstants.colBoundingBox} TEXT,
        ${SchemaConstants.colModelMetadata} TEXT,
        FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');
    batch.execute('CREATE INDEX idx_detected_memory ON ${SchemaConstants.tableDetectedObjects}(${SchemaConstants.colMemoryId});');
    batch.execute('CREATE INDEX idx_detected_label ON ${SchemaConstants.tableDetectedObjects}(${SchemaConstants.colLabel});');

    // 3. Item Identities Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableItemIdentities} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colName} TEXT NOT NULL,
        ${SchemaConstants.colCategory} TEXT NOT NULL,
        ${SchemaConstants.colDescription} TEXT,
        ${SchemaConstants.colReferencePhotoPath} TEXT,
        ${SchemaConstants.colReferenceObjectId} TEXT,
        ${SchemaConstants.colLastObservedMemoryId} TEXT,
        ${SchemaConstants.colLastObservedAt} TEXT,
        ${SchemaConstants.colLastObservedLocation} TEXT,
        ${SchemaConstants.colStatus} TEXT NOT NULL DEFAULT 'lastObserved',
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL
      );
    ''');
    batch.execute('CREATE INDEX idx_item_category ON ${SchemaConstants.tableItemIdentities}(${SchemaConstants.colCategory});');

    // 4. Item Observations Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableItemObservations} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colItemId} TEXT NOT NULL,
        ${SchemaConstants.colMemoryId} TEXT NOT NULL,
        ${SchemaConstants.colDetectedObjectId} TEXT,
        ${SchemaConstants.colObservedAt} TEXT NOT NULL,
        ${SchemaConstants.colLocationLabel} TEXT NOT NULL,
        ${SchemaConstants.colMatchConfidence} REAL NOT NULL,
        ${SchemaConstants.colUserConfirmation} TEXT NOT NULL DEFAULT 'pending',
        ${SchemaConstants.colManualLocationOverride} TEXT,
        ${SchemaConstants.colNotes} TEXT,
        FOREIGN KEY (${SchemaConstants.colItemId}) REFERENCES ${SchemaConstants.tableItemIdentities} (${SchemaConstants.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');
    batch.execute('CREATE INDEX idx_obs_item ON ${SchemaConstants.tableItemObservations}(${SchemaConstants.colItemId});');
    batch.execute('CREATE INDEX idx_obs_memory ON ${SchemaConstants.tableItemObservations}(${SchemaConstants.colMemoryId});');

    // 5. Collections Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableCollections} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colName} TEXT NOT NULL,
        ${SchemaConstants.colIconName} TEXT NOT NULL,
        ${SchemaConstants.colDescription} TEXT,
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL
      );
    ''');

    // 6. Collection Memberships Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableCollectionMemberships} (
        ${SchemaConstants.colCollectionId} TEXT NOT NULL,
        ${SchemaConstants.colMemoryId} TEXT NOT NULL,
        PRIMARY KEY (${SchemaConstants.colCollectionId}, ${SchemaConstants.colMemoryId}),
        FOREIGN KEY (${SchemaConstants.colCollectionId}) REFERENCES ${SchemaConstants.tableCollections} (${SchemaConstants.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');

    // 7. Embeddings Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableEmbeddings} (
        ${SchemaConstants.colMemoryId} TEXT PRIMARY KEY,
        ${SchemaConstants.colVectorJson} TEXT NOT NULL,
        ${SchemaConstants.colDimension} INTEGER NOT NULL,
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');

    // 8. App Settings Table
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableAppSettings} (
        ${SchemaConstants.colKey} TEXT PRIMARY KEY,
        ${SchemaConstants.colValue} TEXT NOT NULL
      );
    ''');

    // 9. Routines Table (v2)
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableRoutines} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colName} TEXT NOT NULL,
        ${SchemaConstants.colIconName} TEXT NOT NULL,
        ${SchemaConstants.colRoutineCategory} TEXT NOT NULL DEFAULT 'general',
        ${SchemaConstants.colScheduledTime} TEXT,
        ${SchemaConstants.colIsReminderEnabled} INTEGER NOT NULL DEFAULT 0,
        ${SchemaConstants.colDescription} TEXT,
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL
      );
    ''');

    // 10. Routine Items Table (v2)
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableRoutineItems} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colRoutineId} TEXT NOT NULL,
        ${SchemaConstants.colItemId} TEXT NOT NULL,
        ${SchemaConstants.colIsVerifiedPacked} INTEGER NOT NULL DEFAULT 0,
        ${SchemaConstants.colLastVerifiedAt} TEXT,
        FOREIGN KEY (${SchemaConstants.colRoutineId}) REFERENCES ${SchemaConstants.tableRoutines} (${SchemaConstants.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${SchemaConstants.colItemId}) REFERENCES ${SchemaConstants.tableItemIdentities} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');

    // 11. Search Feedback Table (v2)
    batch.execute('''
      CREATE TABLE ${SchemaConstants.tableSearchFeedback} (
        ${SchemaConstants.colId} TEXT PRIMARY KEY,
        ${SchemaConstants.colQuery} TEXT NOT NULL,
        ${SchemaConstants.colMemoryId} TEXT NOT NULL,
        ${SchemaConstants.colMatchedObjectLabel} TEXT,
        ${SchemaConstants.colIsPositive} INTEGER NOT NULL,
        ${SchemaConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
      );
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${SchemaConstants.tableItemIdentities} ADD COLUMN ${SchemaConstants.colReferencePhotoPath} TEXT;');
      await db.execute('ALTER TABLE ${SchemaConstants.tableItemIdentities} ADD COLUMN ${SchemaConstants.colReferenceObjectId} TEXT;');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${SchemaConstants.tableRoutines} (
          ${SchemaConstants.colId} TEXT PRIMARY KEY,
          ${SchemaConstants.colName} TEXT NOT NULL,
          ${SchemaConstants.colIconName} TEXT NOT NULL,
          ${SchemaConstants.colDescription} TEXT,
          ${SchemaConstants.colCreatedAt} TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${SchemaConstants.tableRoutineItems} (
          ${SchemaConstants.colId} TEXT PRIMARY KEY,
          ${SchemaConstants.colRoutineId} TEXT NOT NULL,
          ${SchemaConstants.colItemId} TEXT NOT NULL,
          ${SchemaConstants.colIsVerifiedPacked} INTEGER NOT NULL DEFAULT 0,
          ${SchemaConstants.colLastVerifiedAt} TEXT,
          FOREIGN KEY (${SchemaConstants.colRoutineId}) REFERENCES ${SchemaConstants.tableRoutines} (${SchemaConstants.colId}) ON DELETE CASCADE,
          FOREIGN KEY (${SchemaConstants.colItemId}) REFERENCES ${SchemaConstants.tableItemIdentities} (${SchemaConstants.colId}) ON DELETE CASCADE
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${SchemaConstants.tableSearchFeedback} (
          ${SchemaConstants.colId} TEXT PRIMARY KEY,
          ${SchemaConstants.colQuery} TEXT NOT NULL,
          ${SchemaConstants.colMemoryId} TEXT NOT NULL,
          ${SchemaConstants.colMatchedObjectLabel} TEXT,
          ${SchemaConstants.colIsPositive} INTEGER NOT NULL,
          ${SchemaConstants.colCreatedAt} TEXT NOT NULL,
          FOREIGN KEY (${SchemaConstants.colMemoryId}) REFERENCES ${SchemaConstants.tableMemories} (${SchemaConstants.colId}) ON DELETE CASCADE
        );
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE ${SchemaConstants.tableRoutines} ADD COLUMN ${SchemaConstants.colRoutineCategory} TEXT NOT NULL DEFAULT \'general\';');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${SchemaConstants.tableRoutines} ADD COLUMN ${SchemaConstants.colScheduledTime} TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${SchemaConstants.tableRoutines} ADD COLUMN ${SchemaConstants.colIsReminderEnabled} INTEGER NOT NULL DEFAULT 0;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${SchemaConstants.tableItemObservations} ADD COLUMN ${SchemaConstants.colManualLocationOverride} TEXT;');
      } catch (_) {}
    }
  }

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }
}
