import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/routine_model.dart';
import '../providers/routines_provider.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'backpack':
        return Icons.backpack_outlined;
      case 'flight':
        return Icons.flight_takeoff;
      case 'work':
      case 'business_center':
        return Icons.business_center;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.checklist_rounded;
    }
  }

  void _showCreateRoutineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'college';
    String selectedIcon = 'school';
    TimeOfDay? selectedTime = const TimeOfDay(hour: 8, minute: 30);
    bool enableReminder = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Smart Departure Routine',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Routine Name',
                        hintText: 'e.g. College Morning, Office Commute, Gym Session',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Items to pack before heading out',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Routine Category',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ('college', 'College', Icons.school),
                        ('office', 'Office', Icons.business_center),
                        ('travel', 'Travel', Icons.flight_takeoff),
                        ('gym', 'Gym', Icons.fitness_center),
                        ('general', 'General', Icons.checklist_rounded),
                      ].map((cat) {
                        final isSelected = selectedCategory == cat.$1;
                        return ChoiceChip(
                          avatar: Icon(cat.$3, size: 16),
                          label: Text(cat.$2),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                selectedCategory = cat.$1;
                                if (cat.$1 == 'college') selectedIcon = 'school';
                                if (cat.$1 == 'office') selectedIcon = 'work';
                                if (cat.$1 == 'travel') selectedIcon = 'flight';
                                if (cat.$1 == 'gym') selectedIcon = 'fitness_center';
                                if (cat.$1 == 'general') selectedIcon = 'checklist';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Scheduled Departure Time & Reminder',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? const TimeOfDay(hour: 8, minute: 30),
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Set Departure Time',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Reminder', style: TextStyle(fontSize: 13)),
                            value: enableReminder,
                            onChanged: (val) {
                              setModalState(() => enableReminder = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select Icon',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ('backpack', Icons.backpack_outlined),
                        ('work', Icons.work_outline),
                        ('fitness_center', Icons.fitness_center),
                        ('flight', Icons.flight_takeoff),
                        ('school', Icons.school_outlined),
                        ('checklist', Icons.checklist),
                      ].map((entry) {
                        final isSelected = selectedIcon == entry.$1;
                        return ChoiceChip(
                          avatar: Icon(entry.$2, size: 16),
                          label: Text(entry.$1),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedIcon = entry.$1);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          final formattedTime = selectedTime?.format(context);
                          ref.read(routinesProvider.notifier).createRoutine(
                                name: name,
                                iconName: selectedIcon,
                                category: selectedCategory,
                                scheduledTime: formattedTime,
                                isReminderEnabled: enableReminder,
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                              );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Create Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routinesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = [
      ('all', 'All', Icons.grid_view),
      ('college', 'College', Icons.school),
      ('office', 'Office', Icons.business_center),
      ('travel', 'Travel', Icons.flight_takeoff),
      ('gym', 'Gym', Icons.fitness_center),
      ('general', 'General', Icons.checklist_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departure Checklists'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRoutineDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Routine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading && state.routines.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(routinesProvider.notifier).loadRoutines(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Explanatory Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.departure_board, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Smart Departure Checklists',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Before leaving home, check off essential belongings. FindMyStuff AI shows where each item was last seen, but requires manual confirmation to ensure nothing is left behind.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Category Filter Bar
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = state.selectedCategory.toLowerCase() == cat.$1.toLowerCase();
                        return FilterChip(
                          avatar: Icon(
                            cat.$3,
                            size: 14,
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          label: Text(
                            cat.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: isDark ? Colors.black : Colors.white,
                          onSelected: (_) {
                            ref.read(routinesProvider.notifier).filterByCategory(cat.$1);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (state.routines.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.checklist_rtl_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            state.selectedCategory != 'all'
                                ? 'No routines found in ${state.selectedCategory} category'
                                : 'No departure routines created yet',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "New Routine" below to build your checklist.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.routines.map((routine) => _RoutineCard(
                          routine: routine,
                          iconData: _getIconData(routine.iconName),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoutineDetailScreen(
                                  routineId: routine.id,
                                  routineName: routine.name,
                                ),
                              ),
                            ).then((_) => ref.read(routinesProvider.notifier).loadRoutines());
                          },
                          onDelete: () {
                            ref.read(routinesProvider.notifier).deleteRoutine(routine.id);
                          },
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final IconData iconData;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.iconData,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFullyVerified = routine.isFullyVerified;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFullyVerified
              ? AppColors.confidenceHigh.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isFullyVerified ? AppColors.confidenceHigh : AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconData,
                        color: isFullyVerified ? AppColors.confidenceHigh : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  routine.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (routine.scheduledTime != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  routine.isReminderEnabled ? Icons.alarm_on : Icons.alarm_off,
                                  size: 13,
                                  color: routine.isReminderEnabled ? AppColors.primary : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Departure at ${routine.scheduledTime!}${routine.isReminderEnabled ? ' • Reminder ON' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: routine.isReminderEnabled ? AppColors.primary : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (routine.description != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              routine.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      routine.totalItems == 0
                          ? 'Empty checklist'
                          : '${routine.verifiedItems} of ${routine.totalItems} verified packed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isFullyVerified
                            ? AppColors.confidenceHigh
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    Text(
                      '${(routine.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFullyVerified ? AppColors.confidenceHigh : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: routine.progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFullyVerified ? AppColors.confidenceHigh : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
