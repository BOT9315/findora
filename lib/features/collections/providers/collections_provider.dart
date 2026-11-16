import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/collections_repository.dart';
import '../domain/location_collection.dart';

class CollectionsState {
  final bool isLoading;
  final List<LocationCollection> collections;
  final String? errorMessage;

  const CollectionsState({
    this.isLoading = true,
    this.collections = const [],
    this.errorMessage,
  });

  CollectionsState copyWith({
    bool? isLoading,
    List<LocationCollection>? collections,
    String? errorMessage,
  }) {
    return CollectionsState(
      isLoading: isLoading ?? this.isLoading,
      collections: collections ?? this.collections,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final collectionsProvider =
    StateNotifierProvider<CollectionsNotifier, CollectionsState>((ref) {
  return CollectionsNotifier();
});

class CollectionsNotifier extends StateNotifier<CollectionsState> {
  final CollectionsRepository _repository;

  CollectionsNotifier({CollectionsRepository? repository})
      : _repository = repository ?? CollectionsRepository(),
        super(const CollectionsState()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final list = await _repository.getCollectionsWithCounts();
      state = state.copyWith(isLoading: false, collections: list);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load collections: $e');
    }
  }

  Future<void> addCollection(String name, String icon,
      {String? description}) async {
    try {
      await _repository.createCollection(name, icon,
          description: description);
      await loadCollections();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to create collection: $e');
    }
  }

  Future<void> deleteCollection(String id) async {
    try {
      await _repository.deleteCollection(id);
      await loadCollections();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to delete collection: $e');
    }
  }
}
