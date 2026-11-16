import 'package:flutter/material.dart';

class Routine {
  final String id;
  final String name;
  final String iconName;
  final String category; // college, office, travel, gym, general
  final String? scheduledTime; // e.g. "08:30 AM"
  final bool isReminderEnabled;
  final String? description;
  final DateTime createdAt;
  final int totalItems;
  final int verifiedItems;

  const Routine({
    required this.id,
    required this.name,
    required this.iconName,
    this.category = 'general',
    this.scheduledTime,
    this.isReminderEnabled = false,
    this.description,
    required this.createdAt,
    this.totalItems = 0,
    this.verifiedItems = 0,
  });

  bool get isFullyVerified => totalItems > 0 && verifiedItems == totalItems;

  double get progress => totalItems > 0 ? verifiedItems / totalItems : 0.0;

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'college':
        return Icons.school;
      case 'office':
        return Icons.business_center;
      case 'travel':
        return Icons.flight_takeoff;
      case 'gym':
        return Icons.fitness_center;
      default:
        return Icons.checklist_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'routine_category': category,
      'scheduled_time': scheduledTime,
      'is_reminder_enabled': isReminderEnabled ? 1 : 0,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map, {int total = 0, int verified = 0}) {
    return Routine(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String? ?? 'checklist',
      category: map['routine_category'] as String? ?? 'general',
      scheduledTime: map['scheduled_time'] as String?,
      isReminderEnabled: (map['is_reminder_enabled'] as int? ?? 0) == 1,
      description: map['description'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      totalItems: total,
      verifiedItems: verified,
    );
  }

  Routine copyWith({
    String? id,
    String? name,
    String? iconName,
    String? category,
    String? scheduledTime,
    bool? isReminderEnabled,
    String? description,
    DateTime? createdAt,
    int? totalItems,
    int? verifiedItems,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      totalItems: totalItems ?? this.totalItems,
      verifiedItems: verifiedItems ?? this.verifiedItems,
    );
  }
}

class RoutineItemDetail {
  final String routineItemId;
  final String routineId;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final String? itemReferencePhotoPath;
  final bool isVerifiedPacked;
  final DateTime? lastVerifiedAt;
  final String? lastObservedLocation;
  final DateTime? lastObservedAt;
  final String? lastObservedMemoryId;
  final String? lastObservedThumbnailPath;

  const RoutineItemDetail({
    required this.routineItemId,
    required this.routineId,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    this.itemReferencePhotoPath,
    required this.isVerifiedPacked,
    this.lastVerifiedAt,
    this.lastObservedLocation,
    this.lastObservedAt,
    this.lastObservedMemoryId,
    this.lastObservedThumbnailPath,
  });

  /// Distinct status explanation ensuring an item is never claimed to be packed unless verified
  String get statusMessage {
    if (isVerifiedPacked) {
      if (lastVerifiedAt != null) {
        return 'Verified packed by user (${_formatTime(lastVerifiedAt!)})';
      }
      return 'Verified packed by user';
    }
    if (lastObservedLocation != null && lastObservedLocation!.trim().isNotEmpty) {
      final timeStr = lastObservedAt != null ? ' (${_formatTime(lastObservedAt!)})' : '';
      return 'Historical sighting: $lastObservedLocation$timeStr • NOT verified packed';
    }
    return 'No historical sightings • NOT verified packed';
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  RoutineItemDetail copyWith({
    String? routineItemId,
    String? routineId,
    String? itemId,
    String? itemName,
    String? itemCategory,
    String? itemReferencePhotoPath,
    bool? isVerifiedPacked,
    DateTime? lastVerifiedAt,
    String? lastObservedLocation,
    DateTime? lastObservedAt,
    String? lastObservedMemoryId,
    String? lastObservedThumbnailPath,
  }) {
    return RoutineItemDetail(
      routineItemId: routineItemId ?? this.routineItemId,
      routineId: routineId ?? this.routineId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      itemReferencePhotoPath: itemReferencePhotoPath ?? this.itemReferencePhotoPath,
      isVerifiedPacked: isVerifiedPacked ?? this.isVerifiedPacked,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      lastObservedLocation: lastObservedLocation ?? this.lastObservedLocation,
      lastObservedAt: lastObservedAt ?? this.lastObservedAt,
      lastObservedMemoryId: lastObservedMemoryId ?? this.lastObservedMemoryId,
      lastObservedThumbnailPath: lastObservedThumbnailPath ?? this.lastObservedThumbnailPath,
    );
  }
}
