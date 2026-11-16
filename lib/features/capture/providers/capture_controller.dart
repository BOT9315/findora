import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../ai/services/indexing_pipeline.dart';
import '../../memories/data/memory_repository.dart';
import '../../memories/domain/memory_item.dart';

class CaptureState {
  final bool isBusy;
  final File? selectedFile;
  final String locationLabel;
  final String notes;
  final DateTime capturedAt;
  final String? errorMessage;
  final bool isSaved;

  CaptureState({
    this.isBusy = false,
    this.selectedFile,
    this.locationLabel = 'Bedroom',
    this.notes = '',
    DateTime? capturedAt,
    this.errorMessage,
    this.isSaved = false,
  }) : capturedAt = capturedAt ?? DateTime.now();

  CaptureState copyWith({
    bool? isBusy,
    File? selectedFile,
    String? locationLabel,
    String? notes,
    DateTime? capturedAt,
    String? errorMessage,
    bool? isSaved,
    bool clearFile = false,
  }) {
    return CaptureState(
      isBusy: isBusy ?? this.isBusy,
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      locationLabel: locationLabel ?? this.locationLabel,
      notes: notes ?? this.notes,
      capturedAt: capturedAt ?? this.capturedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

final captureProvider =
    StateNotifierProvider.autoDispose<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier();
});

class CaptureNotifier extends StateNotifier<CaptureState> {
  final ImagePicker _picker = ImagePicker();
  final FileStorageService _storageService = FileStorageService.instance;
  final MemoryRepository _memoryRepository = MemoryRepository();
  final IndexingPipeline _indexingPipeline = IndexingPipeline();
  final _uuid = const Uuid();

  CaptureNotifier() : super(CaptureState());

  Future<void> pickFromCamera() async {
    try {
      state = state.copyWith(isBusy: true, errorMessage: null);
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (picked != null) {
        state = state.copyWith(
          isBusy: false,
          selectedFile: File(picked.path),
          capturedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(isBusy: false);
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to open camera: ${e.toString()}',
      );
    }
  }

  Future<void> pickFromGallery() async {
    try {
      state = state.copyWith(isBusy: true, errorMessage: null);
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );

      if (picked != null) {
        state = state.copyWith(
          isBusy: false,
          selectedFile: File(picked.path),
          capturedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(isBusy: false);
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to select from gallery: ${e.toString()}',
      );
    }
  }

  void setLocation(String location) {
    state = state.copyWith(locationLabel: location);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setCapturedAt(DateTime time) {
    state = state.copyWith(capturedAt: time);
  }

  void clearSelection() {
    state = state.copyWith(clearFile: true, errorMessage: null);
  }

  Future<MemoryItem?> saveAndIndex() async {
    if (state.selectedFile == null) {
      state = state.copyWith(
          errorMessage: 'Please capture or choose a photo first');
      return null;
    }

    try {
      state = state.copyWith(isBusy: true, errorMessage: null);

      final savedImages = await _storageService
          .saveImageAndCreateThumbnail(state.selectedFile!);

      final memoryId = _uuid.v4();
      final memory = MemoryItem(
        id: memoryId,
        imagePath: savedImages.originalPath,
        thumbnailPath: savedImages.thumbnailPath,
        capturedAt: state.capturedAt,
        createdAt: DateTime.now(),
        locationLabel: state.locationLabel,
        notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
        indexingStatus: MemoryIndexingStatus.pending,
      );

      await _memoryRepository.insertMemory(memory);

      // Kick off AI indexing in background
      _indexingPipeline.processMemory(memory).then((_) {
        debugPrint('Memory $memoryId background indexing finished');
      });

      state = state.copyWith(isBusy: false, isSaved: true);
      return memory;
    } catch (e) {
      debugPrint('Save error: $e');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Failed to save photo: ${e.toString()}',
      );
      return null;
    }
  }
}
