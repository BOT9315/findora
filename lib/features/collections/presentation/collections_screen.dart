import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/location_collection.dart';
import '../providers/collections_provider.dart';
import 'collection_detail_screen.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  void _showAddCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedIcon = 'room';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Location / Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Collection Name',
                    hintText: 'e.g. Balcony Shelf, Gym Bag, Attic',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _IconOption(
                      icon: Icons.meeting_room,
                      name: 'room',
                      isSelected: selectedIcon == 'room',
                      onSelect: () => setDialogState(() => selectedIcon = 'room'),
                    ),
                    _IconOption(
                      icon: Icons.desk,
                      name: 'desk',
                      isSelected: selectedIcon == 'desk',
                      onSelect: () => setDialogState(() => selectedIcon = 'desk'),
                    ),
                    _IconOption(
                      icon: Icons.backpack,
                      name: 'backpack',
                      isSelected: selectedIcon == 'backpack',
                      onSelect: () => setDialogState(() => selectedIcon = 'backpack'),
                    ),
                    _IconOption(
                      icon: Icons.kitchen,
                      name: 'kitchen',
                      isSelected: selectedIcon == 'kitchen',
                      onSelect: () => setDialogState(() => selectedIcon = 'kitchen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  ref.read(collectionsProvider.notifier).addCollection(
                        nameController.text.trim(),
                        selectedIcon,
                        description: descController.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections & Spaces'),
        actions: [
          IconButton(
            tooltip: 'Add Collection',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCollectionDialog(context, ref),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(collectionsProvider.notifier).loadCollections();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.collections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final col = state.collections[index];
                  return _CollectionTile(collection: col, isDark: isDark);
                },
              ),
            ),
    );
  }
}

class _IconOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool isSelected;
  final VoidCallback onSelect;

  const _IconOption({
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final LocationCollection collection;
  final bool isDark;

  const _CollectionTile({required this.collection, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.meeting_room_outlined;
    if (collection.iconName == 'backpack') icon = Icons.backpack_outlined;
    if (collection.iconName == 'desk') icon = Icons.desk_outlined;
    if (collection.iconName == 'kitchen') icon = Icons.kitchen_outlined;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CollectionDetailScreen(collection: collection),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (collection.description != null && collection.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      collection.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${collection.memoryCount} photos',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
