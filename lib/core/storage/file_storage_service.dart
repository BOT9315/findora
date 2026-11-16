import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class StorageUsage {
  final int photoBytes;
  final int thumbnailBytes;
  final int databaseBytes;
  final int totalFiles;

  const StorageUsage({
    required this.photoBytes,
    required this.thumbnailBytes,
    required this.databaseBytes,
    required this.totalFiles,
  });

  int get totalBytes => photoBytes + thumbnailBytes + databaseBytes;

  String get formattedTotal => _formatBytes(totalBytes);
  String get formattedPhotos => _formatBytes(photoBytes);
  String get formattedThumbnails => _formatBytes(thumbnailBytes);
  String get formattedDatabase => _formatBytes(databaseBytes);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}

class SavedImageResult {
  final String originalPath;
  final String thumbnailPath;
  final int width;
  final int height;

  const SavedImageResult({
    required this.originalPath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
  });
}

class FileStorageService {
  FileStorageService._internal();
  static final FileStorageService instance = FileStorageService._internal();

  final _uuid = const Uuid();

  Future<Directory> get _appDir async {
    return await getApplicationDocumentsDirectory();
  }

  Future<Directory> get photosDirectory async {
    final appDir = await _appDir;
    final dir = Directory(p.join(appDir.path, AppConstants.photosDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> get thumbnailsDirectory async {
    final appDir = await _appDir;
    final dir = Directory(p.join(appDir.path, AppConstants.thumbnailsDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sanitizes filename to prevent directory traversal
  String sanitizeFilename(String filename) {
    final clean = p.basename(filename);
    return clean.replaceAll(RegExp(r'[^\w\.-]'), '_');
  }

  /// Saves an image from a source file into app-private storage and generates a thumbnail
  Future<SavedImageResult> saveImageAndCreateThumbnail(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw Exception('Source image file does not exist: ${sourceFile.path}');
    }

    final bytes = await sourceFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Source image file is empty');
    }

    // Decode image safely
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image file. Format may be unsupported.');
    }

    final id = _uuid.v4();
    final photosDir = await photosDirectory;
    final thumbsDir = await thumbnailsDirectory;

    final originalPath = p.join(photosDir.path, '$id.jpg');
    final thumbnailPath = p.join(thumbsDir.path, '${id}_thumb.jpg');

    // Save original image (re-encode as clean JPEG to standardize format and strip potential exploits)
    final originalBytes = img.encodeJpg(decoded, quality: 90);
    await File(originalPath).writeAsBytes(originalBytes, flush: true);

    // Compute thumbnail dimensions maintaining aspect ratio
    int targetWidth = AppConstants.thumbnailWidth;
    int targetHeight = (decoded.height * (targetWidth / decoded.width)).round();
    if (decoded.width < decoded.height) {
      targetHeight = AppConstants.thumbnailWidth;
      targetWidth = (decoded.width * (targetHeight / decoded.height)).round();
    }

    final thumbnailImage = img.copyResize(
      decoded,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    final thumbBytes = img.encodeJpg(thumbnailImage, quality: AppConstants.thumbnailQuality);
    await File(thumbnailPath).writeAsBytes(thumbBytes, flush: true);

    return SavedImageResult(
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      width: decoded.width,
      height: decoded.height,
    );
  }

  /// Safely deletes original and thumbnail files
  Future<void> deleteFiles({String? originalPath, String? thumbnailPath}) async {
    if (originalPath != null) {
      try {
        final f = File(originalPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        debugPrint('Error deleting original image $originalPath: $e');
      }
    }

    if (thumbnailPath != null) {
      try {
        final f = File(thumbnailPath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        debugPrint('Error deleting thumbnail $thumbnailPath: $e');
      }
    }
  }

  /// Calculates storage used across photos, thumbnails, and database
  Future<StorageUsage> calculateStorageUsage(String databasePath) async {
    int photoBytes = 0;
    int thumbBytes = 0;
    int fileCount = 0;

    final photosDir = await photosDirectory;
    if (await photosDir.exists()) {
      await for (final entity in photosDir.list(followLinks: false)) {
        if (entity is File) {
          photoBytes += await entity.length();
          fileCount++;
        }
      }
    }

    final thumbsDir = await thumbnailsDirectory;
    if (await thumbsDir.exists()) {
      await for (final entity in thumbsDir.list(followLinks: false)) {
        if (entity is File) {
          thumbBytes += await entity.length();
          fileCount++;
        }
      }
    }

    int dbBytes = 0;
    try {
      final dbFile = File(databasePath);
      if (await dbFile.exists()) {
        dbBytes = await dbFile.length();
      }
    } catch (_) {}

    return StorageUsage(
      photoBytes: photoBytes,
      thumbnailBytes: thumbBytes,
      databaseBytes: dbBytes,
      totalFiles: fileCount,
    );
  }

  /// Clean up orphaned files not present in the database
  Future<int> cleanupOrphanedFiles(Set<String> activePaths) async {
    int removedCount = 0;

    final photosDir = await photosDirectory;
    if (await photosDir.exists()) {
      await for (final entity in photosDir.list(followLinks: false)) {
        if (entity is File && !activePaths.contains(entity.path)) {
          try {
            await entity.delete();
            removedCount++;
          } catch (_) {}
        }
      }
    }

    final thumbsDir = await thumbnailsDirectory;
    if (await thumbsDir.exists()) {
      await for (final entity in thumbsDir.list(followLinks: false)) {
        if (entity is File && !activePaths.contains(entity.path)) {
          try {
            await entity.delete();
            removedCount++;
          } catch (_) {}
        }
      }
    }

    return removedCount;
  }

  /// Delete all stored photos and thumbnails
  Future<void> wipeAllStorage() async {
    final photosDir = await photosDirectory;
    if (await photosDir.exists()) {
      await for (final entity in photosDir.list(followLinks: false)) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }

    final thumbsDir = await thumbnailsDirectory;
    if (await thumbsDir.exists()) {
      await for (final entity in thumbsDir.list(followLinks: false)) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }
}
