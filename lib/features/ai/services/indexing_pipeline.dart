import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../items/data/items_repository.dart';
import '../../memories/data/memory_repository.dart';
import '../../memories/domain/memory_item.dart';
import 'embedding_service.dart';
import 'image_analysis_service.dart';

class IndexingPipeline {
  final MemoryRepository _memoryRepository;
  final ItemsRepository _itemsRepository;
  final ImageAnalysisService _analysisService;
  final EmbeddingService _embeddingService;

  IndexingPipeline({
    MemoryRepository? memoryRepository,
    ItemsRepository? itemsRepository,
    ImageAnalysisService? analysisService,
    EmbeddingService? embeddingService,
  })  : _memoryRepository = memoryRepository ?? MemoryRepository(),
        _itemsRepository = itemsRepository ?? ItemsRepository(),
        _analysisService = analysisService ?? ImageAnalysisService.instance,
        _embeddingService = embeddingService ?? EmbeddingService.instance;

  /// Runs full on-device AI indexing pipeline for a newly saved memory
  Future<bool> processMemory(MemoryItem memory) async {
    try {
      // 1. Mark as indexing
      await _memoryRepository.updateMemoryStatus(memory.id, MemoryIndexingStatus.indexing);

      final imageFile = File(memory.imagePath);
      if (!await imageFile.exists()) {
        await _memoryRepository.updateMemoryStatus(
          memory.id,
          MemoryIndexingStatus.failed,
          errorMessage: 'Image file not found on disk',
        );
        return false;
      }

      // 2. Run Image Analysis & Pattern Recognition
      final analysis = await _analysisService.analyzeImage(
        imageFile: imageFile,
        memoryId: memory.id,
        locationLabel: memory.locationLabel,
        userNotes: memory.notes,
      );

      if (!analysis.success) {
        await _memoryRepository.updateMemoryStatus(
          memory.id,
          MemoryIndexingStatus.failed,
          errorMessage: analysis.errorMessage ?? 'Vision analysis failed',
        );
        return false;
      }

      // 3. Persist detected objects
      await _memoryRepository.saveDetectedObjects(memory.id, analysis.detectedObjects);

      // 4. Generate & store dense embedding
      await _embeddingService.generateImageEmbedding(
        memoryId: memory.id,
        detectedObjects: analysis.detectedObjects,
        locationLabel: memory.locationLabel,
        visualMetadata: analysis.visualMetadata,
        notes: memory.notes,
      );

      // 5. Automatically group detected objects into item identities and sightings history
      for (final obj in analysis.detectedObjects) {
        await _itemsRepository.autoLinkDetectedObject(
          memoryId: memory.id,
          label: obj.label,
          locationLabel: memory.locationLabel,
          capturedAt: memory.capturedAt,
          confidence: obj.confidence,
          detectedObjectId: obj.id,
        );
      }

      // 6. Mark indexing as completed
      await _memoryRepository.updateMemoryStatus(memory.id, MemoryIndexingStatus.completed);
      return true;
    } catch (e, stack) {
      debugPrint('Indexing pipeline exception: $e\n$stack');
      await _memoryRepository.updateMemoryStatus(
        memory.id,
        MemoryIndexingStatus.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Retries indexing for a failed memory
  Future<bool> retryIndexing(String memoryId) async {
    final memory = await _memoryRepository.getMemoryById(memoryId);
    if (memory == null) return false;
    return await processMemory(memory);
  }

  /// Re-indexes all existing memories (useful after software updates or custom model reload)
  Future<int> reindexAll() async {
    final all = await _memoryRepository.getAllMemories(limit: 500);
    int successCount = 0;
    for (final mem in all) {
      final ok = await processMemory(mem);
      if (ok) successCount++;
    }
    return successCount;
  }
}
