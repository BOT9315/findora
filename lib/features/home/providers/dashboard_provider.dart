import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/schema_constants.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../ai/services/indexing_pipeline.dart';
import '../../collections/data/collections_repository.dart';
import '../../collections/domain/location_collection.dart';
import '../../memories/data/memory_repository.dart';
import '../../memories/domain/memory_item.dart';

class DashboardState {
  final bool isLoading;
  final int totalMemories;
  final int indexedMemories;
  final int failedMemories;
  final List<MemoryItem> recentMemories;
  final List<LocationCollection> collections;
  final StorageUsage? storageUsage;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = true,
    this.totalMemories = 0,
    this.indexedMemories = 0,
    this.failedMemories = 0,
    this.recentMemories = const [],
    this.collections = const [],
    this.storageUsage,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    int? totalMemories,
    int? indexedMemories,
    int? failedMemories,
    List<MemoryItem>? recentMemories,
    List<LocationCollection>? collections,
    StorageUsage? storageUsage,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalMemories: totalMemories ?? this.totalMemories,
      indexedMemories: indexedMemories ?? this.indexedMemories,
      failedMemories: failedMemories ?? this.failedMemories,
      recentMemories: recentMemories ?? this.recentMemories,
      collections: collections ?? this.collections,
      storageUsage: storageUsage ?? this.storageUsage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final MemoryRepository _memoryRepository;
  final CollectionsRepository _collectionsRepository;
  final FileStorageService _storageService;
  final IndexingPipeline _indexingPipeline;

  DashboardNotifier({
    MemoryRepository? memoryRepository,
    CollectionsRepository? collectionsRepository,
    FileStorageService? storageService,
    IndexingPipeline? indexingPipeline,
  })  : _memoryRepository = memoryRepository ?? MemoryRepository(),
        _collectionsRepository =
            collectionsRepository ?? CollectionsRepository(),
        _storageService = storageService ?? FileStorageService.instance,
        _indexingPipeline = indexingPipeline ?? IndexingPipeline(),
        super(const DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final total = await _memoryRepository.getMemoryCount();
      final indexed = await _memoryRepository.getIndexedCount();
      final failed = await _memoryRepository.getFailedIndexingCount();
      final recents = await _memoryRepository.getRecentMemories(limit: 10);
      final collections =
          await _collectionsRepository.getCollectionsWithCounts();

      StorageUsage? storage;
      try {
        storage = await _storageService
            .calculateStorageUsage(SchemaConstants.databaseName);
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        totalMemories: total,
        indexedMemories: indexed,
        failedMemories: failed,
        recentMemories: recents,
        collections: collections,
        storageUsage: storage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard: ${e.toString()}',
      );
    }
  }

  Future<void> retryFailedIndexing() async {
    final failed = await _memoryRepository.getFailedMemories();
    for (final mem in failed) {
      await _indexingPipeline.retryIndexing(mem.id);
    }
    await loadDashboard();
  }
}
