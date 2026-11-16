import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../../../core/security/app_lock_service.dart';
import '../../../core/storage/backup_service.dart';
import '../../../core/storage/file_storage_service.dart';
import '../../ai/services/indexing_pipeline.dart';

class SettingsState {
  final bool isLoading;
  final bool isAppLockEnabled;
  final bool canUseBiometrics;
  final bool speakResultsEnabled;
  final StorageUsage? storageUsage;
  final String? message;
  final String? errorMessage;

  const SettingsState({
    this.isLoading = false,
    this.isAppLockEnabled = false,
    this.canUseBiometrics = false,
    this.speakResultsEnabled = false,
    this.storageUsage,
    this.message,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isLoading,
    bool? isAppLockEnabled,
    bool? canUseBiometrics,
    bool? speakResultsEnabled,
    StorageUsage? storageUsage,
    String? message,
    String? errorMessage,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      speakResultsEnabled: speakResultsEnabled ?? this.speakResultsEnabled,
      storageUsage: storageUsage ?? this.storageUsage,
      message: message,
      errorMessage: errorMessage,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final AppLockService _appLockService = AppLockService.instance;
  final FileStorageService _storageService = FileStorageService.instance;
  final BackupService _backupService = BackupService.instance;
  final IndexingPipeline _indexingPipeline = IndexingPipeline();

  SettingsNotifier() : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final lockEnabled = await _appLockService.isAppLockEnabled();
      final biometricsSupported =
          await _appLockService.canCheckBiometrics();
      final speakSetting = await AppDatabase.instance.getSetting('speak_search_results');

      StorageUsage? usage;
      try {
        usage = await _storageService
            .calculateStorageUsage(SchemaConstants.databaseName);
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        isAppLockEnabled: lockEnabled,
        canUseBiometrics: biometricsSupported,
        speakResultsEnabled: speakSetting == 'true',
        storageUsage: usage,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to load settings: $e');
    }
  }

  Future<bool> toggleAppLock(bool enable) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final success = await _appLockService.setAppLockEnabled(enable);
    if (success) {
      state = state.copyWith(
        isLoading: false,
        isAppLockEnabled: enable,
        message: enable
            ? 'App Lock enabled with biometrics'
            : 'App Lock disabled',
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'Biometric authentication was cancelled or failed.',
      );
      return false;
    }
  }

  Future<void> toggleSpeakResults(bool enable) async {
    await AppDatabase.instance.setSetting('speak_search_results', enable ? 'true' : 'false');
    state = state.copyWith(speakResultsEnabled: enable);
  }

  Future<BackupResult> createBackup() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _backupService.createBackup();
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        message:
            'Backup created successfully (${result.totalMemories} memories archived)',
      );
    } else {
      state =
          state.copyWith(isLoading: false, errorMessage: result.error);
    }
    return result;
  }

  Future<RestoreResult> restoreBackup(File file) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _backupService.restoreBackup(file);
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        message:
            'Restored ${result.restoredMemories} memories successfully!',
      );
      await loadSettings();
    } else {
      state =
          state.copyWith(isLoading: false, errorMessage: result.error);
    }
    return result;
  }

  Future<void> reindexAllPhotos() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final count = await _indexingPipeline.reindexAll();
    state = state.copyWith(
      isLoading: false,
      message: 'Re-indexed $count photographs with the vision model.',
    );
  }

  Future<void> wipeAllData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await AppDatabase.instance.wipeAllData();
      await _storageService.wipeAllStorage();
      state = state.copyWith(
        isLoading: false,
        message:
            'All local memories, items, and photos have been securely deleted.',
      );
      await loadSettings();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to wipe data: $e');
    }
  }
}
