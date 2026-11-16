import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/services/indexing_pipeline.dart';
import '../data/memory_repository.dart';
import '../domain/memory_item.dart';

class MemoryListState {
  final bool isLoading;
  final List<MemoryItem> memories;
  final String? selectedLocation;
  final String? errorMessage;

  const MemoryListState({
    this.isLoading = true,
    this.memories = const [],
    this.selectedLocation,
    this.errorMessage,
  });

  MemoryListState copyWith({
    bool? isLoading,
    List<MemoryItem>? memories,
    String? selectedLocation,
    String? errorMessage,
    bool clearLocation = false,
  }) {
    return MemoryListState(
      isLoading: isLoading ?? this.isLoading,
      memories: memories ?? this.memories,
      selectedLocation:
          clearLocation ? null : (selectedLocation ?? this.selectedLocation),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final memoryListProvider =
    StateNotifierProvider<MemoryListNotifier, MemoryListState>((ref) {
  return MemoryListNotifier();
});

class MemoryListNotifier extends StateNotifier<MemoryListState> {
  final MemoryRepository _repository;
  final IndexingPipeline _pipeline;

  MemoryListNotifier({
    MemoryRepository? repository,
    IndexingPipeline? pipeline,
  })  : _repository = repository ?? MemoryRepository(),
        _pipeline = pipeline ?? IndexingPipeline(),
        super(const MemoryListState()) {
    loadMemories();
  }

  Future<void> loadMemories({String? locationFilter}) async {
    try {
      state = state.copyWith(
          isLoading: true,
          errorMessage: null,
          selectedLocation: locationFilter);
      final list =
          await _repository.getAllMemories(locationFilter: locationFilter);
      state = state.copyWith(isLoading: false, memories: list);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to load memories: $e');
    }
  }

  Future<void> filterByLocation(String? location) async {
    if (location == null) {
      state = state.copyWith(clearLocation: true);
      await loadMemories(locationFilter: null);
    } else {
      await loadMemories(locationFilter: location);
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await _repository.deleteMemory(id);
      final updated = state.memories.where((m) => m.id != id).toList();
      state = state.copyWith(memories: updated);
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete memory: $e');
    }
  }

  Future<void> updateMemory({
    required String id,
    required String location,
    String? notes,
    required DateTime capturedAt,
  }) async {
    try {
      await _repository.updateMemoryDetails(
        id: id,
        locationLabel: location,
        notes: notes,
        capturedAt: capturedAt,
      );
      await loadMemories(locationFilter: state.selectedLocation);
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update memory: $e');
    }
  }

  Future<void> retryIndexing(String id) async {
    await _pipeline.retryIndexing(id);
    await loadMemories(locationFilter: state.selectedLocation);
  }
}
