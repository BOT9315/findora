import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/services/embedding_service.dart';
import '../data/search_feedback_repository.dart';
import '../data/search_service.dart';
import '../domain/search_query_model.dart';
import '../domain/search_result_item.dart';

class SearchState {
  final bool isSearching;
  final String query;
  final String? locationFilter;
  final TimeFilter timeFilter;
  final String? categoryFilter;
  final String? colorFilter;
  final List<SearchResultItem> results;
  final bool hasSearched;
  final String? errorMessage;

  const SearchState({
    this.isSearching = false,
    this.query = '',
    this.locationFilter,
    this.timeFilter = TimeFilter.any,
    this.categoryFilter,
    this.colorFilter,
    this.results = const [],
    this.hasSearched = false,
    this.errorMessage,
  });

  bool get hasActiveFilters =>
      locationFilter != null ||
      timeFilter != TimeFilter.any ||
      categoryFilter != null ||
      colorFilter != null;

  SearchState copyWith({
    bool? isSearching,
    String? query,
    String? locationFilter,
    TimeFilter? timeFilter,
    String? categoryFilter,
    String? colorFilter,
    List<SearchResultItem>? results,
    bool? hasSearched,
    String? errorMessage,
    bool clearLocation = false,
    bool clearCategory = false,
    bool clearColor = false,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      query: query ?? this.query,
      locationFilter: clearLocation ? null : (locationFilter ?? this.locationFilter),
      timeFilter: timeFilter ?? this.timeFilter,
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      colorFilter: clearColor ? null : (colorFilter ?? this.colorFilter),
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;

  SearchNotifier({SearchService? searchService})
      : _searchService = searchService ?? SearchService(),
        super(const SearchState());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty && !state.hasActiveFilters) {
      state = state.copyWith(
        query: '',
        results: [],
        hasSearched: false,
        errorMessage: null,
      );
      return;
    }

    try {
      state = state.copyWith(
        isSearching: true,
        query: trimmed,
        hasSearched: true,
        errorMessage: null,
      );

      final results = await _searchService.search(
        trimmed,
        locationOverride: state.locationFilter,
        timeOverride: state.timeFilter,
        categoryOverride: state.categoryFilter,
        colorOverride: state.colorFilter,
      );

      state = state.copyWith(
        isSearching: false,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Search encountered an error: $e',
      );
    }
  }

  Future<void> searchWithImage(File imageFile, {String? queryLabel}) async {
    try {
      state = state.copyWith(
        isSearching: true,
        query: queryLabel ?? 'Visual Search',
        hasSearched: true,
        errorMessage: null,
      );

      final imageEmbedding = await EmbeddingService.instance.generateImageQueryEmbedding(imageFile);
      final results = await _searchService.search(
        queryLabel ?? 'visual similarity match',
        locationOverride: state.locationFilter,
        timeOverride: state.timeFilter,
        categoryOverride: state.categoryFilter,
        colorOverride: state.colorFilter,
        queryEmbeddingOverride: imageEmbedding,
      );

      state = state.copyWith(
        isSearching: false,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Visual search error: $e',
      );
    }
  }

  void setLocationFilter(String? location) {
    if (location == null) {
      state = state.copyWith(clearLocation: true);
    } else {
      state = state.copyWith(locationFilter: location);
    }
    search(state.query);
  }

  void setTimeFilter(TimeFilter filter) {
    state = state.copyWith(timeFilter: filter);
    search(state.query);
  }

  void setCategoryFilter(String? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryFilter: category);
    }
    search(state.query);
  }

  void setColorFilter(String? color) {
    if (color == null) {
      state = state.copyWith(clearColor: true);
    } else {
      state = state.copyWith(colorFilter: color);
    }
    search(state.query);
  }

  void clearFilters() {
    state = state.copyWith(
      clearLocation: true,
      clearCategory: true,
      clearColor: true,
      timeFilter: TimeFilter.any,
    );
    search(state.query);
  }

  Future<void> setFeedback(String memoryId, bool isPositive) async {
    final repo = SearchFeedbackRepository();
    await repo.recordFeedback(
      memoryId: memoryId,
      query: state.query,
      isPositive: isPositive,
    );
    // Refresh search results ranking
    if (state.hasSearched) {
      await search(state.query);
    }
  }
}
