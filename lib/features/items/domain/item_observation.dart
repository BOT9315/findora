enum ConfirmationStatus {
  pending,
  confirmed,
  rejected;

  String get displayName {
    switch (this) {
      case ConfirmationStatus.pending:
        return 'Pending Review';
      case ConfirmationStatus.confirmed:
        return 'Confirmed';
      case ConfirmationStatus.rejected:
        return 'Rejected';
    }
  }

  static ConfirmationStatus fromString(String val) {
    switch (val) {
      case 'confirmed':
        return ConfirmationStatus.confirmed;
      case 'rejected':
        return ConfirmationStatus.rejected;
      case 'pending':
      default:
        return ConfirmationStatus.pending;
    }
  }
}

class ItemObservation {
  final String id;
  final String itemId;
  final String memoryId;
  final String? detectedObjectId;
  final DateTime observedAt;
  final String locationLabel;
  final String? manualLocationOverride;
  final double matchConfidence;
  final ConfirmationStatus userConfirmation;
  final String? notes;

  const ItemObservation({
    required this.id,
    required this.itemId,
    required this.memoryId,
    this.detectedObjectId,
    required this.observedAt,
    required this.locationLabel,
    this.manualLocationOverride,
    required this.matchConfidence,
    this.userConfirmation = ConfirmationStatus.pending,
    this.notes,
  });

  /// Effective location: uses manual correction if provided by user, otherwise photo location
  String get displayLocation =>
      (manualLocationOverride != null && manualLocationOverride!.trim().isNotEmpty)
          ? manualLocationOverride!
          : locationLabel;

  bool get hasManualCorrection =>
      manualLocationOverride != null && manualLocationOverride!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'memory_id': memoryId,
      'detected_object_id': detectedObjectId,
      'observed_at': observedAt.toIso8601String(),
      'location_label': locationLabel,
      'manual_location_override': manualLocationOverride,
      'match_confidence': matchConfidence,
      'user_confirmation': userConfirmation.name,
      'notes': notes,
    };
  }

  factory ItemObservation.fromMap(Map<String, dynamic> map) {
    return ItemObservation(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      memoryId: map['memory_id'] as String,
      detectedObjectId: map['detected_object_id'] as String?,
      observedAt: DateTime.parse(map['observed_at'] as String),
      locationLabel: map['location_label'] as String,
      manualLocationOverride: map['manual_location_override'] as String?,
      matchConfidence: (map['match_confidence'] as num).toDouble(),
      userConfirmation: ConfirmationStatus.fromString((map['user_confirmation'] as String?) ?? 'pending'),
      notes: map['notes'] as String?,
    );
  }

  ItemObservation copyWith({
    String? id,
    String? itemId,
    String? memoryId,
    String? detectedObjectId,
    DateTime? observedAt,
    String? locationLabel,
    String? manualLocationOverride,
    double? matchConfidence,
    ConfirmationStatus? userConfirmation,
    String? notes,
  }) {
    return ItemObservation(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      memoryId: memoryId ?? this.memoryId,
      detectedObjectId: detectedObjectId ?? this.detectedObjectId,
      observedAt: observedAt ?? this.observedAt,
      locationLabel: locationLabel ?? this.locationLabel,
      manualLocationOverride: manualLocationOverride ?? this.manualLocationOverride,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      userConfirmation: userConfirmation ?? this.userConfirmation,
      notes: notes ?? this.notes,
    );
  }
}
