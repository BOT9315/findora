import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/items_repository.dart';
import '../domain/item_identity.dart';
import '../domain/item_observation.dart';

class ItemsState {
  final bool isLoading;
  final List<ItemIdentity> items;
  final String? errorMessage;

  const ItemsState({
    this.isLoading = true,
    this.items = const [],
    this.errorMessage,
  });

  ItemsState copyWith({
    bool? isLoading,
    List<ItemIdentity>? items,
    String? errorMessage,
  }) {
    return ItemsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  return ItemsNotifier();
});

class ItemsNotifier extends StateNotifier<ItemsState> {
  final ItemsRepository _repository;
  final _uuid = const Uuid();

  ItemsNotifier({ItemsRepository? repository})
      : _repository = repository ?? ItemsRepository(),
        super(const ItemsState()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final list = await _repository.getAllItems();
      state = state.copyWith(isLoading: false, items: list);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to load items: $e');
    }
  }

  Future<List<ItemObservation>> getObservationsForItem(
      String itemId) async {
    return await _repository.getObservationsForItem(itemId);
  }

  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      await _repository.updateItemStatus(itemId, status);
      await loadItems();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update item status: $e');
    }
  }

  Future<void> confirmObservation(
      String observationId, ConfirmationStatus status) async {
    try {
      await _repository.updateObservationConfirmation(
          observationId, status);
      await loadItems();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to confirm observation: $e');
    }
  }

  Future<void> updateObservationLocation(
      String observationId, String newLocation) async {
    try {
      await _repository.updateObservationLocation(observationId, newLocation);
      await loadItems();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update observation location: $e');
    }
  }

  Future<void> createCustomItem({
    required String name,
    required String category,
    String? description,
    String? referencePhotoPath,
  }) async {
    try {
      final newItem = ItemIdentity(
        id: _uuid.v4(),
        name: name.trim(),
        category: category.trim(),
        description: description?.trim(),
        referencePhotoPath: referencePhotoPath,
        createdAt: DateTime.now(),
      );
      await _repository.saveItem(newItem);
      // Scan for potential historical observations without auto-merging
      await _repository.scanForPotentialMatches(newItem.id);
      await loadItems();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create item: $e');
    }
  }

  Future<List<ItemObservation>> scanForPotentialMatches(String itemId) async {
    final list = await _repository.scanForPotentialMatches(itemId);
    await loadItems();
    return list;
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteItem(itemId);
      await loadItems();
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete item: $e');
    }
  }
}
