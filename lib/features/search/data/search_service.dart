import 'dart:math' as math;
import '../../../core/constants/app_constants.dart';
import '../../ai/domain/detected_object.dart';
import '../../ai/services/embedding_service.dart';
import '../../memories/data/memory_repository.dart';
import '../domain/search_query_model.dart';
import '../domain/search_result_item.dart';
import 'query_parser.dart';
import 'search_feedback_repository.dart';

class SearchService {
  final MemoryRepository _memoryRepository;
  final EmbeddingService _embeddingService;
  final SearchFeedbackRepository _feedbackRepository;

  SearchService({
    MemoryRepository? memoryRepository,
    EmbeddingService? embeddingService,
    SearchFeedbackRepository? feedbackRepository,
  })  : _memoryRepository = memoryRepository ?? MemoryRepository(),
        _embeddingService = embeddingService ?? EmbeddingService.instance,
        _feedbackRepository = feedbackRepository ?? SearchFeedbackRepository();

  Future<List<SearchResultItem>> search(
    String rawQuery, {
    String? locationOverride,
    TimeFilter? timeOverride,
    String? categoryOverride,
    String? colorOverride,
    List<double>? queryEmbeddingOverride,
  }) async {
    final query = QueryParser.parse(rawQuery);
    final effectiveLocation = locationOverride ?? query.targetLocation;
    final effectiveTime = (timeOverride != null && timeOverride != TimeFilter.any) ? timeOverride : query.timeFilter;
    final effectiveCategory = categoryOverride ?? query.targetItem;
    final effectiveColor = colorOverride ?? query.targetColor;

    // Load candidate memories from database
    final memories = await _memoryRepository.getAllMemories(
      limit: 200,
      locationFilter: effectiveLocation,
    );

    if (memories.isEmpty) {
      return [];
    }

    // Load stored embeddings
    final embeddings = await _embeddingService.getAllEmbeddings();
    final queryEmbedding = queryEmbeddingOverride ?? _embeddingService.generateQueryEmbedding(rawQuery);

    final List<SearchResultItem> results = [];
    final now = DateTime.now();

    for (final memory in memories) {
      // Apply time filter
      if (!_satisfiesTimeFilter(memory.capturedAt, effectiveTime, now)) {
        continue;
      }

      // Apply explicit category filter if specified
      if (categoryOverride != null &&
          !memory.detectedObjects.any((o) =>
              o.label.toLowerCase().contains(categoryOverride.toLowerCase()))) {
        continue;
      }

      // Apply explicit color filter if specified
      if (colorOverride != null &&
          !memory.detectedObjects.any((o) =>
              (o.color?.toLowerCase().contains(colorOverride.toLowerCase()) ?? false) ||
              o.label.toLowerCase().contains(colorOverride.toLowerCase()))) {
        continue;
      }

      // 1. Compute Object & Attribute Match Score
      DetectedObject? bestMatchedObject;
      double objectScore = 0.0;
      final List<String> highlights = [];

      for (final obj in memory.detectedObjects) {
        double currentObjScore = 0.0;

        // Label Match
        if (effectiveCategory != null && obj.label.toLowerCase() == effectiveCategory.toLowerCase()) {
          currentObjScore += 0.65 * obj.confidence;
          highlights.add('Object: ${obj.label}');
        } else if (query.keywords.any((kw) => obj.label.toLowerCase().contains(kw))) {
          currentObjScore += 0.45 * obj.confidence;
          highlights.add('Object: ${obj.label}');
        }

        // Color Match
        final objColor = obj.color?.toLowerCase();
        if (effectiveColor != null && objColor != null && objColor.contains(effectiveColor.toLowerCase())) {
          currentObjScore += 0.35;
          highlights.add('Color: ${obj.color}');
        }

        // Attribute / Material / Spatial match
        if (obj.material != null && query.keywords.any((kw) => obj.material!.toLowerCase().contains(kw))) {
          currentObjScore += 0.15;
        }

        if (currentObjScore > objectScore) {
          objectScore = currentObjScore;
          bestMatchedObject = obj;
        }
      }

      // 2. Compute Metadata & Notes Match Score
      double metadataScore = 0.0;
      final locLower = memory.locationLabel.toLowerCase();
      final notesLower = (memory.notes ?? '').toLowerCase();

      if (effectiveLocation != null && locLower.contains(effectiveLocation.toLowerCase())) {
        metadataScore += 0.30;
        highlights.add('Location: ${memory.locationLabel}');
      }

      for (final kw in query.keywords) {
        if (notesLower.contains(kw)) {
          metadataScore += 0.20;
          highlights.add('Note match: "$kw"');
        }
        if (locLower.contains(kw) && metadataScore < 0.40) {
          metadataScore += 0.20;
          highlights.add('Room match: "$kw"');
        }
      }

      // 3. Compute Semantic Embedding Cosine Similarity
      double semanticScore = 0.0;
      final memoryEmb = embeddings[memory.id];
      if (memoryEmb != null) {
        semanticScore = memoryEmb.cosineSimilarity(queryEmbedding);
        if (semanticScore > 0.45) {
          highlights.add('AI Visual match: ${(semanticScore * 100).toInt()}%');
        }
      }

      // Combine relevance factors
      // If we have an exact object match, give high weight
      double relevanceScore = (objectScore * 0.45) + (metadataScore * 0.25) + (semanticScore * 0.30);
      relevanceScore = relevanceScore.clamp(0.0, 1.0);

      // Filter out totally irrelevant photos unless broad search
      if (relevanceScore < AppConstants.minRelevanceThreshold && query.keywords.isNotEmpty) {
        continue;
      }

      // 4. Compute Recency Score (smooth half-life of 14 days)
      final ageHours = now.difference(memory.capturedAt).inHours;
      final ageDays = ageHours / 24.0;
      // Exponential decay: e^(-0.05 * days)
      final recencyScore = math.exp(-0.0495 * ageDays).clamp(0.0, 1.0);

      // 5. Incorporate User Feedback Adjustment (Personalized Ranking)
      final feedbackAdjustment = await _feedbackRepository.getRankingAdjustment(memory.id, rawQuery);
      final userFeedback = await _feedbackRepository.getFeedbackStatus(memory.id, rawQuery);
      if (feedbackAdjustment > 0) {
        highlights.add('User confirmed (+${(feedbackAdjustment * 100).toInt()}%)');
      } else if (feedbackAdjustment < 0) {
        highlights.add('User penalized (${(feedbackAdjustment * 100).toInt()}%)');
      }

      // 6. Balanced Combined Ranking (Relevance 80%, Recency 20% + Feedback Adjustment)
      final combinedScore = ((relevanceScore * 0.80) + (recencyScore * 0.20) + feedbackAdjustment).clamp(0.01, 1.0);

      // Build explainable match reason
      String reason;
      if (bestMatchedObject != null && highlights.isNotEmpty) {
        reason = 'Matched ${bestMatchedObject.label} in ${memory.locationLabel} (${highlights.join(', ')})';
      } else if (highlights.isNotEmpty) {
        reason = 'Matched ${highlights.join(' • ')}';
      } else {
        reason = 'Visual similarity match in ${memory.locationLabel}';
      }

      results.add(SearchResultItem(
        memory: memory,
        matchedObject: bestMatchedObject,
        relevanceScore: relevanceScore,
        recencyScore: recencyScore,
        combinedScore: combinedScore,
        matchReason: reason,
        matchedHighlights: highlights,
        userFeedback: userFeedback,
        scoreBreakdown: ScoreBreakdown(
          semanticScore: semanticScore,
          objectScore: objectScore,
          metadataScore: metadataScore,
          recencyScore: recencyScore,
          feedbackBoost: feedbackAdjustment,
          combinedScore: combinedScore,
        ),
      ));
    }

    // Sort by combined score descending
    results.sort((a, b) => b.combinedScore.compareTo(a.combinedScore));

    return results.take(AppConstants.maxSearchResults).toList();
  }

  bool _satisfiesTimeFilter(DateTime capturedAt, TimeFilter filter, DateTime now) {
    switch (filter) {
      case TimeFilter.today:
        return capturedAt.year == now.year &&
            capturedAt.month == now.month &&
            capturedAt.day == now.day;
      case TimeFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return capturedAt.year == yesterday.year &&
            capturedAt.month == yesterday.month &&
            capturedAt.day == yesterday.day;
      case TimeFilter.thisWeek:
        return now.difference(capturedAt).inDays <= 7;
      case TimeFilter.thisMonth:
        return now.difference(capturedAt).inDays <= 30;
      case TimeFilter.any:
        return true;
    }
  }
}
