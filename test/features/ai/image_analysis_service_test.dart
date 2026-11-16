// Unit tests for ImageAnalysisService and EmbeddingService - verifies fallback
// behavior, graceful error handling, query embedding generation, and cosine similarity.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_stuff_ai/features/ai/domain/visual_embedding.dart';
import 'package:find_my_stuff_ai/features/ai/services/image_analysis_service.dart';
import 'package:find_my_stuff_ai/features/ai/services/embedding_service.dart';

void main() {
  group('ImageAnalysisService', () {
    test('analyzeImage returns failure gracefully when image file does not exist', () async {
      final service = ImageAnalysisService.instance;
      final result = await service.analyzeImage(
        imageFile: File('C:/nonexistent/path/image.jpg'),
        memoryId: 'test-mem-001',
        locationLabel: 'Desk',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('does not exist'));
      expect(result.detectedObjects, isEmpty);
    });
  });

  group('EmbeddingService', () {
    test('generateQueryEmbedding returns 64-dimensional normalized vector', () {
      final service = EmbeddingService.instance;
      final vector = service.generateQueryEmbedding('black charger on my study desk');

      expect(vector.length, equals(EmbeddingService.embeddingDimension));
      expect(vector.length, equals(64));

      // L2 norm of the vector should be close to 1.0 (since it is normalized)
      double normSq = 0.0;
      for (final v in vector) {
        normSq += v * v;
      }
      expect(normSq, closeTo(1.0, 0.01));
    });

    test('query embeddings for related tokens have higher similarity than unrelated', () {
      final service = EmbeddingService.instance;
      final vecCharger1 = service.generateQueryEmbedding('black usb charger');
      final vecCharger2 = service.generateQueryEmbedding('black fast charger');
      final vecKeys = service.generateQueryEmbedding('house keys keychain metal');

      final embCharger = VisualEmbedding(
        memoryId: 'charger-1',
        vector: vecCharger1,
        dimension: 64,
        createdAt: DateTime.now(),
      );

      final simRelated = embCharger.cosineSimilarity(vecCharger2);
      final simUnrelated = embCharger.cosineSimilarity(vecKeys);

      expect(simRelated, greaterThan(simUnrelated));
    });

    test('cosine similarity is 1.0 for identical vectors', () {
      final vec = List<double>.filled(64, 0.0);
      vec[0] = 1.0;

      final emb = VisualEmbedding(
        memoryId: 'test-1',
        vector: vec,
        dimension: 64,
        createdAt: DateTime.now(),
      );

      final sim = emb.cosineSimilarity(vec);
      expect(sim, closeTo(1.0, 0.001));
    });

    test('cosine similarity is 0.0 for orthogonal vectors', () {
      final vecA = List<double>.filled(64, 0.0);
      final vecB = List<double>.filled(64, 0.0);
      vecA[0] = 1.0;
      vecB[1] = 1.0;

      final embA = VisualEmbedding(
        memoryId: 'test-a',
        vector: vecA,
        dimension: 64,
        createdAt: DateTime.now(),
      );

      final sim = embA.cosineSimilarity(vecB);
      expect(sim, closeTo(0.0, 0.001));
    });
  });
}
