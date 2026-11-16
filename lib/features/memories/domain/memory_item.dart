import '../../ai/domain/detected_object.dart';

enum MemoryIndexingStatus {
  pending,
  indexing,
  completed,
  failed;

  String get displayName {
    switch (this) {
      case MemoryIndexingStatus.pending:
        return 'Pending';
      case MemoryIndexingStatus.indexing:
        return 'Indexing';
      case MemoryIndexingStatus.completed:
        return 'Indexed';
      case MemoryIndexingStatus.failed:
        return 'Index Failed';
    }
  }

  static MemoryIndexingStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'indexing':
        return MemoryIndexingStatus.indexing;
      case 'completed':
        return MemoryIndexingStatus.completed;
      case 'failed':
        return MemoryIndexingStatus.failed;
      case 'pending':
      default:
        return MemoryIndexingStatus.pending;
    }
  }
}

class MemoryItem {
  final String id;
  final String imagePath;
  final String thumbnailPath;
  final DateTime capturedAt;
  final DateTime createdAt;
  final String locationLabel;
  final String? notes;
  final MemoryIndexingStatus indexingStatus;
  final String? errorMessage;
  final List<DetectedObject> detectedObjects;

  const MemoryItem({
    required this.id,
    required this.imagePath,
    required this.thumbnailPath,
    required this.capturedAt,
    required this.createdAt,
    required this.locationLabel,
    this.notes,
    this.indexingStatus = MemoryIndexingStatus.pending,
    this.errorMessage,
    this.detectedObjects = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'thumbnail_path': thumbnailPath,
      'captured_at': capturedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'location_label': locationLabel,
      'notes': notes,
      'indexing_status': indexingStatus.name,
      'error_message': errorMessage,
    };
  }

  factory MemoryItem.fromMap(Map<String, dynamic> map, {List<DetectedObject> objects = const []}) {
    return MemoryItem(
      id: map['id'] as String,
      imagePath: map['image_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      locationLabel: map['location_label'] as String,
      notes: map['notes'] as String?,
      indexingStatus: MemoryIndexingStatus.fromString((map['indexing_status'] as String?) ?? 'pending'),
      errorMessage: map['error_message'] as String?,
      detectedObjects: objects,
    );
  }

  MemoryItem copyWith({
    String? id,
    String? imagePath,
    String? thumbnailPath,
    DateTime? capturedAt,
    DateTime? createdAt,
    String? locationLabel,
    String? notes,
    MemoryIndexingStatus? indexingStatus,
    String? errorMessage,
    List<DetectedObject>? detectedObjects,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      locationLabel: locationLabel ?? this.locationLabel,
      notes: notes ?? this.notes,
      indexingStatus: indexingStatus ?? this.indexingStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      detectedObjects: detectedObjects ?? this.detectedObjects,
    );
  }
}
