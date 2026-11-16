import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/routines_repository.dart';
import '../domain/routine_model.dart';

final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository();
});

class RoutinesState {
  final bool isLoading;
  final List<Routine> routines;
  final String selectedCategory; // 'all', 'college', 'office', 'travel', 'gym', 'general'
  final String? errorMessage;

  const RoutinesState({
    this.isLoading = false,
    this.routines = const [],
    this.selectedCategory = 'all',
    this.errorMessage,
  });

  RoutinesState copyWith({
    bool? isLoading,
    List<Routine>? routines,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return RoutinesState(
      isLoading: isLoading ?? this.isLoading,
      routines: routines ?? this.routines,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }
}

class RoutinesNotifier extends StateNotifier<RoutinesState> {
  final RoutinesRepository _repository;

  RoutinesNotifier(this._repository) : super(const RoutinesState()) {
    loadRoutines();
  }

  Future<void> loadRoutines({String? category}) async {
    final cat = category ?? state.selectedCategory;
    state = state.copyWith(isLoading: true, errorMessage: null, selectedCategory: cat);
    try {
      final routines = await _repository.getAllRoutines(category: cat);
      state = state.copyWith(isLoading: false, routines: routines);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load routines: $e');
    }
  }

  void filterByCategory(String category) {
    loadRoutines(category: category);
  }

  Future<void> createRoutine({
    required String name,
    required String iconName,
    String category = 'general',
    String? scheduledTime,
    bool isReminderEnabled = false,
    String? description,
  }) async {
    try {
      await _repository.createRoutine(
        name: name,
        iconName: iconName,
        category: category,
        scheduledTime: scheduledTime,
        isReminderEnabled: isReminderEnabled,
        description: description,
      );
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create routine: $e');
    }
  }

  Future<void> updateSchedule(Routine routine, {String? scheduledTime, bool? isReminderEnabled}) async {
    try {
      final updated = routine.copyWith(
        scheduledTime: scheduledTime ?? routine.scheduledTime,
        isReminderEnabled: isReminderEnabled ?? routine.isReminderEnabled,
      );
      await _repository.updateRoutine(updated);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update routine schedule: $e');
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _repository.deleteRoutine(routineId);
      await loadRoutines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete routine: $e');
    }
  }
}

final routinesProvider = StateNotifierProvider<RoutinesNotifier, RoutinesState>((ref) {
  final repo = ref.watch(routinesRepositoryProvider);
  return RoutinesNotifier(repo);
});

class RoutineDetailState {
  final bool isLoading;
  final Routine? routine;
  final List<RoutineItemDetail> items;
  final String? errorMessage;

  const RoutineDetailState({
    this.isLoading = false,
    this.routine,
    this.items = const [],
    this.errorMessage,
  });

  RoutineDetailState copyWith({
    bool? isLoading,
    Routine? routine,
    List<RoutineItemDetail>? items,
    String? errorMessage,
  }) {
    return RoutineDetailState(
      isLoading: isLoading ?? this.isLoading,
      routine: routine ?? this.routine,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class RoutineDetailNotifier extends StateNotifier<RoutineDetailState> {
  final RoutinesRepository _repository;
  final String routineId;

  RoutineDetailNotifier(this._repository, this.routineId) : super(const RoutineDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final routine = await _repository.getRoutineById(routineId);
      final items = await _repository.getRoutineItems(routineId);
      state = state.copyWith(
        isLoading: false,
        routine: routine,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load checklist: $e');
    }
  }

  Future<void> toggleItemVerification(String routineItemId, bool currentValue) async {
    try {
      final newValue = !currentValue;
      await _repository.setItemVerifiedPacked(routineItemId, newValue);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update verification: $e');
    }
  }

  Future<void> addItem(String itemId) async {
    try {
      await _repository.addItemToRoutine(routineId, itemId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add item: $e');
    }
  }

  Future<void> removeItem(String routineItemId) async {
    try {
      await _repository.removeItemFromRoutine(routineItemId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove item: $e');
    }
  }

  Future<void> resetAll() async {
    try {
      await _repository.resetAllVerifications(routineId);
      await loadDetail();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reset checklist: $e');
    }
  }
}

final routineDetailProvider = StateNotifierProvider.family<RoutineDetailNotifier, RoutineDetailState, String>((ref, routineId) {
  final repo = ref.watch(routinesRepositoryProvider);
  return RoutineDetailNotifier(repo, routineId);
});
