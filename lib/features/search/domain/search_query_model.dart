enum TimeFilter {
  any,
  today,
  yesterday,
  thisWeek,
  thisMonth;

  String get displayName {
    switch (this) {
      case TimeFilter.any:
        return 'Any Time';
      case TimeFilter.today:
        return 'Today';
      case TimeFilter.yesterday:
        return 'Yesterday';
      case TimeFilter.thisWeek:
        return 'Past 7 Days';
      case TimeFilter.thisMonth:
        return 'Past 30 Days';
    }
  }
}

class SearchQueryModel {
  final String rawQuery;
  final String? targetItem;
  final String? targetColor;
  final String? targetLocation;
  final TimeFilter timeFilter;
  final List<String> keywords;

  const SearchQueryModel({
    required this.rawQuery,
    this.targetItem,
    this.targetColor,
    this.targetLocation,
    this.timeFilter = TimeFilter.any,
    this.keywords = const [],
  });

  bool get hasFilters =>
      targetItem != null ||
      targetColor != null ||
      targetLocation != null ||
      timeFilter != TimeFilter.any;
}
