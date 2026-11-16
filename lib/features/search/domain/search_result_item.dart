import '../../ai/domain/detected_object.dart';
import '../../memories/domain/memory_item.dart';

class ScoreBreakdown {
  final double semanticScore;
  final double objectScore;
  final double metadataScore;
  final double recencyScore;
  final double feedbackBoost;
  final double combinedScore;

  const ScoreBreakdown({
    required this.semanticScore,
    required this.objectScore,
    required this.metadataScore,
    required this.recencyScore,
    this.feedbackBoost = 0.0,
    required this.combinedScore,
  });

  String get summary =>
      'AI Semantic: ${(semanticScore * 100).toInt()}% • '
      'Object Match: ${(objectScore * 100).toInt()}% • '
      'Metadata: ${(metadataScore * 100).toInt()}% • '
      'Recency: ${(recencyScore * 100).toInt()}%';
}

class SearchResultItem {
  final MemoryItem memory;
  final DetectedObject? matchedObject;
  final double relevanceScore; // 0.0 to 1.0 (semantic + keyword + object)
  final double recencyScore;   // 0.0 to 1.0 (smooth time decay)
  final double combinedScore;  // Weighted combined score
  final String matchReason;    // Human-readable explanation of why this was matched
  final List<String> matchedHighlights;
  final ScoreBreakdown scoreBreakdown;
  final int userFeedback; // 1 for thumbs up, -1 for thumbs down, 0 for none

  const SearchResultItem({
    required this.memory,
    this.matchedObject,
    required this.relevanceScore,
    required this.recencyScore,
    required this.combinedScore,
    required this.matchReason,
    this.matchedHighlights = const [],
    this.userFeedback = 0,
    this.scoreBreakdown = const ScoreBreakdown(
      semanticScore: 0.0,
      objectScore: 0.0,
      metadataScore: 0.0,
      recencyScore: 0.0,
      combinedScore: 0.0,
    ),
  });

  SearchResultItem copyWith({
    MemoryItem? memory,
    DetectedObject? matchedObject,
    double? relevanceScore,
    double? recencyScore,
    double? combinedScore,
    String? matchReason,
    List<String>? matchedHighlights,
    ScoreBreakdown? scoreBreakdown,
    int? userFeedback,
  }) {
    return SearchResultItem(
      memory: memory ?? this.memory,
      matchedObject: matchedObject ?? this.matchedObject,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      recencyScore: recencyScore ?? this.recencyScore,
      combinedScore: combinedScore ?? this.combinedScore,
      matchReason: matchReason ?? this.matchReason,
      matchedHighlights: matchedHighlights ?? this.matchedHighlights,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  /// Formatted observation disclaimer
  String get observationDisclaimer =>
      'Last recorded at ${memory.locationLabel} • Physical presence cannot be guaranteed';
}
