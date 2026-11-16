import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../database/app_database.dart';
import '../database/schema_constants.dart';
import 'file_storage_service.dart';

class BackupResult {
  final bool success;
  final String? backupFilePath;
  final int totalMemories;
  final String? error;

  const BackupResult({
    required this.success,
    this.backupFilePath,
    this.totalMemories = 0,
    this.error,
  });
}

class RestoreResult {
  final bool success;
  final int restoredMemories;
  final String? error;

  const RestoreResult({
    required this.success,
    this.restoredMemories = 0,
    this.error,
  });
}

class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  /// Creates a compressed ZIP backup containing data.json and photos
  Future<BackupResult> createBackup() async {
    try {
      final db = await AppDatabase.instance.database;

      final memoriesData =
          await db.query(SchemaConstants.tableMemories);
      final detectedObjectsData =
          await db.query(SchemaConstants.tableDetectedObjects);
      final itemIdentitiesData =
          await db.query(SchemaConstants.tableItemIdentities);
      final itemObservationsData =
          await db.query(SchemaConstants.tableItemObservations);
      final collectionsData =
          await db.query(SchemaConstants.tableCollections);
      final collectionMembershipsData =
          await db.query(SchemaConstants.tableCollectionMemberships);

      final manifest = {
        'version': 1,
        'appName': AppConstants.appName,
        'createdAt': DateTime.now().toIso8601String(),
        'memories': memoriesData,
        'detectedObjects': detectedObjectsData,
        'itemIdentities': itemIdentitiesData,
        'itemObservations': itemObservationsData,
        'collections': collectionsData,
        'collectionMemberships': collectionMembershipsData,
      };

      final archive = Archive();

      // Add data.json
      final jsonBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(
          ArchiveFile('data.json', jsonBytes.length, jsonBytes));

      // Add photos
      for (final mem in memoriesData) {
        final imgPath = mem[SchemaConstants.colImagePath] as String?;
        if (imgPath != null) {
          final file = File(imgPath);
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            final fileName = p.basename(imgPath);
            archive.addFile(
                ArchiveFile('photos/$fileName', fileBytes.length, fileBytes));
          }
        }
      }

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      final tempDir = await getTemporaryDirectory();
      final dateStr =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath =
          p.join(tempDir.path, 'findmystuff_backup_$dateStr.fmszip');
      await File(backupPath).writeAsBytes(zipData, flush: true);

      return BackupResult(
        success: true,
        backupFilePath: backupPath,
        totalMemories: memoriesData.length,
      );
    } catch (e) {
      debugPrint('Backup creation error: $e');
      return BackupResult(success: false, error: e.toString());
    }
  }

  /// Restores from a ZIP backup file
  Future<RestoreResult> restoreBackup(File backupZipFile) async {
    try {
      if (!await backupZipFile.exists()) {
        return const RestoreResult(
            success: false, error: 'Backup file does not exist');
      }

      final bytes = await backupZipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? jsonFile;
      for (final file in archive) {
        if (file.name == 'data.json') {
          jsonFile = file;
          break;
        }
      }

      if (jsonFile == null) {
        return const RestoreResult(
            success: false,
            error: 'Invalid backup: missing data.json');
      }

      final content = utf8.decode(jsonFile.content as List<int>);
      final manifest = jsonDecode(content) as Map<String, dynamic>;

      final memories =
          (manifest['memories'] as List<dynamic>?) ?? [];
      final detectedObjects =
          (manifest['detectedObjects'] as List<dynamic>?) ?? [];
      final itemIdentities =
          (manifest['itemIdentities'] as List<dynamic>?) ?? [];
      final itemObservations =
          (manifest['itemObservations'] as List<dynamic>?) ?? [];
      final collections =
          (manifest['collections'] as List<dynamic>?) ?? [];
      final collectionMemberships =
          (manifest['collectionMemberships'] as List<dynamic>?) ?? [];

      final photosDir =
          await FileStorageService.instance.photosDirectory;
      final thumbsDir =
          await FileStorageService.instance.thumbnailsDirectory;

      final db = await AppDatabase.instance.database;

      await db.transaction((txn) async {
        for (final mem in memories) {
          final m = Map<String, dynamic>.from(mem as Map);
          final oldImgPath = m[SchemaConstants.colImagePath] as String;
          final fileName = p.basename(oldImgPath);
          final newImgPath = p.join(photosDir.path, fileName);
          final newThumbPath = p.join(thumbsDir.path,
              '${p.basenameWithoutExtension(fileName)}_thumb.jpg');

          for (final file in archive) {
            if (file.name == 'photos/$fileName') {
              final photoFile = File(newImgPath);
              await photoFile.writeAsBytes(file.content as List<int>,
                  flush: true);
              break;
            }
          }

          m[SchemaConstants.colImagePath] = newImgPath;
          m[SchemaConstants.colThumbnailPath] = newThumbPath;

          await txn.insert(SchemaConstants.tableMemories, m,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in detectedObjects) {
          await txn.insert(
              SchemaConstants.tableDetectedObjects,
              Map<String, dynamic>.from(item as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in itemIdentities) {
          await txn.insert(
              SchemaConstants.tableItemIdentities,
              Map<String, dynamic>.from(item as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in itemObservations) {
          await txn.insert(
              SchemaConstants.tableItemObservations,
              Map<String, dynamic>.from(item as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in collections) {
          await txn.insert(
              SchemaConstants.tableCollections,
              Map<String, dynamic>.from(item as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in collectionMemberships) {
          await txn.insert(
              SchemaConstants.tableCollectionMemberships,
              Map<String, dynamic>.from(item as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      return RestoreResult(
          success: true, restoredMemories: memories.length);
    } catch (e) {
      debugPrint('Backup restoration error: $e');
      return RestoreResult(success: false, error: e.toString());
    }
  }
}
