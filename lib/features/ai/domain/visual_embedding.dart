import 'dart:convert';
import 'dart:math' as math;

class VisualEmbedding {
  final String memoryId;
  final List<double> vector;
  final int dimension;
  final DateTime createdAt;

  const VisualEmbedding({
    required this.memoryId,
    required this.vector,
    required this.dimension,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'memory_id': memoryId,
      'vector_json': jsonEncode(vector),
      'dimension': dimension,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory VisualEmbedding.fromMap(Map<String, dynamic> map) {
    final list = (jsonDecode(map['vector_json'] as String) as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    return VisualEmbedding(
      memoryId: map['memory_id'] as String,
      vector: list,
      dimension: map['dimension'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Calculates cosine similarity between this vector and another vector
  double cosineSimilarity(List<double> other) {
    if (vector.length != other.length || vector.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vector.length; i++) {
      dotProduct += vector[i] * other[i];
      normA += vector[i] * vector[i];
      normB += other[i] * other[i];
    }

    if (normA <= 0.0 || normB <= 0.0) return 0.0;
    final similarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));
    return similarity.clamp(0.0, 1.0);
  }
}
