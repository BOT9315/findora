import 'dart:convert';

class BoundingBox {
  final double left; // Normalized 0.0 - 1.0
  final double top;
  final double width;
  final double height;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  factory BoundingBox.fromMap(Map<String, dynamic> map) {
    return BoundingBox(
      left: (map['left'] as num).toDouble(),
      top: (map['top'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());
  static BoundingBox? fromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BoundingBox.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}

class DetectedObject {
  final String id;
  final String memoryId;
  final String label;
  final double confidence;
  final Map<String, dynamic> attributes;
  final BoundingBox? boundingBox;
  final String? modelMetadata;

  const DetectedObject({
    required this.id,
    required this.memoryId,
    required this.label,
    required this.confidence,
    this.attributes = const {},
    this.boundingBox,
    this.modelMetadata,
  });

  String? get color => attributes['color'] as String?;
  String? get spatialQuadrant => attributes['spatial'] as String?;
  String? get material => attributes['material'] as String?;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memory_id': memoryId,
      'label': label,
      'confidence': confidence,
      'attributes': jsonEncode(attributes),
      'bounding_box': boundingBox?.toJson(),
      'model_metadata': modelMetadata,
    };
  }

  factory DetectedObject.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> attrs = {};
    if (map['attributes'] != null && (map['attributes'] as String).isNotEmpty) {
      try {
        attrs = Map<String, dynamic>.from(jsonDecode(map['attributes'] as String) as Map);
      } catch (_) {}
    }

    return DetectedObject(
      id: map['id'] as String,
      memoryId: map['memory_id'] as String,
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      attributes: attrs,
      boundingBox: BoundingBox.fromJson(map['bounding_box'] as String?),
      modelMetadata: map['model_metadata'] as String?,
    );
  }

  DetectedObject copyWith({
    String? id,
    String? memoryId,
    String? label,
    double? confidence,
    Map<String, dynamic>? attributes,
    BoundingBox? boundingBox,
    String? modelMetadata,
  }) {
    return DetectedObject(
      id: id ?? this.id,
      memoryId: memoryId ?? this.memoryId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      attributes: attributes ?? this.attributes,
      boundingBox: boundingBox ?? this.boundingBox,
      modelMetadata: modelMetadata ?? this.modelMetadata,
    );
  }
}
