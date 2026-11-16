enum ItemStatus {
  lastObserved,
  foundAndConfirmed,
  movedAndConfirmed,
  locationUnknown;

  String get displayName {
    switch (this) {
      case ItemStatus.lastObserved:
        return 'Last Observed';
      case ItemStatus.foundAndConfirmed:
        return 'Found & Confirmed';
      case ItemStatus.movedAndConfirmed:
        return 'Moved & Confirmed';
      case ItemStatus.locationUnknown:
        return 'Location Unknown';
    }
  }

  static ItemStatus fromString(String val) {
    switch (val) {
      case 'foundAndConfirmed':
        return ItemStatus.foundAndConfirmed;
      case 'movedAndConfirmed':
        return ItemStatus.movedAndConfirmed;
      case 'locationUnknown':
        return ItemStatus.locationUnknown;
      case 'lastObserved':
      default:
        return ItemStatus.lastObserved;
    }
  }
}

class ItemIdentity {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? referencePhotoPath;
  final String? referenceObjectId;
  final String? lastObservedMemoryId;
  final DateTime? lastObservedAt;
  final String? lastObservedLocation;
  final ItemStatus status;
  final DateTime createdAt;

  const ItemIdentity({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.referencePhotoPath,
    this.referenceObjectId,
    this.lastObservedMemoryId,
    this.lastObservedAt,
    this.lastObservedLocation,
    this.status = ItemStatus.lastObserved,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'reference_photo_path': referencePhotoPath,
      'reference_object_id': referenceObjectId,
      'last_observed_memory_id': lastObservedMemoryId,
      'last_observed_at': lastObservedAt?.toIso8601String(),
      'last_observed_location': lastObservedLocation,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemIdentity.fromMap(Map<String, dynamic> map) {
    return ItemIdentity(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      referencePhotoPath: map['reference_photo_path'] as String?,
      referenceObjectId: map['reference_object_id'] as String?,
      lastObservedMemoryId: map['last_observed_memory_id'] as String?,
      lastObservedAt: map['last_observed_at'] != null ? DateTime.parse(map['last_observed_at'] as String) : null,
      lastObservedLocation: map['last_observed_location'] as String?,
      status: ItemStatus.fromString((map['status'] as String?) ?? 'lastObserved'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  ItemIdentity copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? referencePhotoPath,
    String? referenceObjectId,
    String? lastObservedMemoryId,
    DateTime? lastObservedAt,
    String? lastObservedLocation,
    ItemStatus? status,
    DateTime? createdAt,
  }) {
    return ItemIdentity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      referencePhotoPath: referencePhotoPath ?? this.referencePhotoPath,
      referenceObjectId: referenceObjectId ?? this.referenceObjectId,
      lastObservedMemoryId: lastObservedMemoryId ?? this.lastObservedMemoryId,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      lastObservedLocation: lastObservedLocation ?? this.lastObservedLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
