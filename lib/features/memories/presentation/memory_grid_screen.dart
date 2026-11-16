import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../capture/presentation/capture_screen.dart';
import '../providers/memory_provider.dart';
import 'memory_detail_screen.dart';

class MemoryGridScreen extends ConsumerWidget {
  const MemoryGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Memories'),
        actions: [
          IconButton(
            tooltip: 'Add Photo',
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CaptureScreen()),
              ).then((_) => ref.read(memoryListProvider.notifier).loadMemories());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('All Locations'),
                  selected: state.selectedLocation == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(memoryListProvider.notifier).filterByLocation(null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...AppConstants.defaultLocations.map((loc) {
                  final isSelected = state.selectedLocation == loc;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(loc),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(memoryListProvider.notifier).filterByLocation(selected ? loc : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // Grid View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.memories.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 56,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.selectedLocation != null
                                    ? 'No memories in ${state.selectedLocation}'
                                    : 'No photographic memories saved yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Capture photos of your spaces and belongings to build your visual memory bank.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const CaptureScreen()),
                                  ).then((_) => ref.read(memoryListProvider.notifier).loadMemories());
                                },
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Capture First Photo'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(memoryListProvider.notifier).loadMemories(
                                locationFilter: state.selectedLocation,
                              );
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: state.memories.length,
                          itemBuilder: (context, index) {
                            final mem = state.memories[index];
                            final file = File(mem.thumbnailPath);
                            final fallbackFile = File(mem.imagePath);

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MemoryDetailScreen(memoryId: mem.id),
                                  ),
                                ).then((_) => ref.read(memoryListProvider.notifier).loadMemories(
                                      locationFilter: state.selectedLocation,
                                    ));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          file.existsSync()
                                              ? Image.file(file, fit: BoxFit.cover)
                                              : fallbackFile.existsSync()
                                                  ? Image.file(fallbackFile, fit: BoxFit.cover)
                                                  : Container(
                                                      color: Colors.grey.shade900,
                                                      child: const Icon(Icons.broken_image, color: Colors.white54),
                                                    ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                mem.indexingStatus.displayName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mem.locationLabel,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('MMM d, yyyy • h:mm a').format(mem.capturedAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                            ),
                                          ),
                                          if (mem.detectedObjects.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              mem.detectedObjects.map((o) => o.label).join(', '),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
