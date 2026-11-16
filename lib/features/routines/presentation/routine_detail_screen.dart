import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../items/providers/items_provider.dart';
import '../../memories/presentation/memory_detail_screen.dart';
import '../domain/routine_model.dart';
import '../providers/routines_provider.dart';

class RoutineDetailScreen extends ConsumerWidget {
  final String routineId;
  final String routineName;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
    required this.routineName,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'backpack':
        return Icons.backpack_outlined;
      case 'flight':
        return Icons.flight_takeoff;
      case 'work':
        return Icons.work_outline;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.checklist;
    }
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    final itemsState = ref.read(itemsProvider);
    final detailState = ref.read(routineDetailProvider(routineId));
    final existingItemIds = detailState.items.map((i) => i.itemId).toSet();
    final availableItems = itemsState.items.where((i) => !existingItemIds.contains(i.id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Item to Checklist',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a registered item to track in this departure routine:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: availableItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              itemsState.items.isEmpty
                                  ? 'No registered items yet. Create items in the Items tab first!'
                                  : 'All registered items are already in this routine.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: availableItems.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final item = availableItems[index];
                          return ListTile(
                            leading: item.referencePhotoPath != null &&
                                    File(item.referencePhotoPath!).existsSync()
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(item.referencePhotoPath!),
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.category, color: AppColors.primary, size: 22),
                                  ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              item.lastObservedLocation != null
                                  ? 'Last seen: ${item.lastObservedLocation}'
                                  : 'Category: ${item.category}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onTap: () {
                              ref.read(routineDetailProvider(routineId).notifier).addItem(item.id);
                              ref.read(routinesProvider.notifier).loadRoutines();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added "${item.name}" to checklist')),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Checklist?'),
        content: const Text(
          'This will mark all items as unverified for your next departure. Historical observations will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(routineDetailProvider(routineId).notifier).resetAll();
              ref.read(routinesProvider.notifier).loadRoutines();
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routineDetailProvider(routineId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final routine = state.routine;
    final items = state.items;
    final verifiedCount = items.where((i) => i.isVerifiedPacked).length;
    final totalCount = items.length;
    final isAllVerified = totalCount > 0 && verifiedCount == totalCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(routine?.name ?? routineName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Checklist',
            onPressed: items.isEmpty ? null : () => _showResetConfirmation(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(routineDetailProvider(routineId).notifier).loadDetail();
                await ref.read(routinesProvider.notifier).loadRoutines();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Checklist Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAllVerified
                            ? AppColors.confidenceHigh
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isAllVerified ? AppColors.confidenceHigh : AppColors.primary)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAllVerified ? Icons.check_circle : _getIconData(routine?.iconName ?? 'checklist'),
                                color: isAllVerified ? AppColors.confidenceHigh : AppColors.primary,
                                size: 26,
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
                                          isAllVerified
                                              ? 'All Items Verified Packed!'
                                              : '$verifiedCount of $totalCount items verified',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if (routine != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            routine.category.toUpperCase(),
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    routine?.description ?? 'Departure checklist',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  if (routine?.scheduledTime != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          routine!.isReminderEnabled ? Icons.alarm_on : Icons.alarm_off,
                                          size: 13,
                                          color: routine.isReminderEnabled ? AppColors.primary : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Departure at ${routine.scheduledTime!}${routine.isReminderEnabled ? ' • Reminder Active' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: routine.isReminderEnabled ? AppColors.primary : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: totalCount > 0 ? verifiedCount / totalCount : 0.0,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAllVerified ? AppColors.confidenceHigh : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Privacy & Verification Policy Alert
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.confidenceMedium.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.confidenceMedium.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 20, color: AppColors.confidenceMedium),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Historical observations show where an item was recorded in the past. An item is NEVER claimed to be packed unless you explicitly verify it here.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checklist Items',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tap checkbox to verify',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.checklist_rtl, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No items in this routine yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "Add Item" below to select registered belongings for this checklist.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...items.map((item) => _RoutineItemCard(
                          item: item,
                          onToggle: () {
                            ref
                                .read(routineDetailProvider(routineId).notifier)
                                .toggleItemVerification(item.routineItemId, item.isVerifiedPacked);
                            ref.read(routinesProvider.notifier).loadRoutines();
                          },
                          onDelete: () {
                            ref
                                .read(routineDetailProvider(routineId).notifier)
                                .removeItem(item.routineItemId);
                            ref.read(routinesProvider.notifier).loadRoutines();
                          },
                          onViewMemory: item.lastObservedMemoryId != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailScreen(
                                        memoryId: item.lastObservedMemoryId!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _RoutineItemCard extends StatelessWidget {
  final RoutineItemDetail item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onViewMemory;

  const _RoutineItemCard({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    this.onViewMemory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key('routine_item_${item.routineItemId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isVerifiedPacked
              ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE8F5E9))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isVerifiedPacked
                ? AppColors.confidenceHigh.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Transform.scale(
              scale: 1.15,
              child: Checkbox(
                value: item.isVerifiedPacked,
                activeColor: AppColors.confidenceHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => onToggle(),
              ),
            ),
            const SizedBox(width: 8),

            // Item Thumbnail
            if (item.itemReferencePhotoPath != null && File(item.itemReferencePhotoPath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(item.itemReferencePhotoPath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else if (item.lastObservedThumbnailPath != null &&
                File(item.lastObservedThumbnailPath!).existsSync())
              GestureDetector(
                onTap: onViewMemory,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(item.lastObservedThumbnailPath!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (item.isVerifiedPacked ? AppColors.confidenceHigh : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: item.isVerifiedPacked ? AppColors.confidenceHigh : AppColors.primary,
                  size: 22,
                ),
              ),

            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: item.isVerifiedPacked ? TextDecoration.lineThrough : null,
                            color: item.isVerifiedPacked
                                ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.itemCategory,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item.isVerifiedPacked ? Icons.verified : Icons.info_outline,
                        size: 13,
                        color: item.isVerifiedPacked ? AppColors.confidenceHigh : AppColors.confidenceMedium,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.statusMessage,
                          style: TextStyle(
                            fontSize: 11,
                            color: item.isVerifiedPacked
                                ? AppColors.confidenceHigh
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
