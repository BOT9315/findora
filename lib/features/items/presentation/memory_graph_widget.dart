import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../memories/data/memory_repository.dart';
import '../../memories/domain/memory_item.dart';
import '../../memories/presentation/memory_detail_screen.dart';
import '../domain/item_observation.dart';

class MemoryGraphWidget extends StatefulWidget {
  final String itemName;
  final List<ItemObservation> observations;
  final Function(String observationId, String newLocation) onLocationCorrected;

  const MemoryGraphWidget({
    super.key,
    required this.itemName,
    required this.observations,
    required this.onLocationCorrected,
  });

  @override
  State<MemoryGraphWidget> createState() => _MemoryGraphWidgetState();
}

class _MemoryGraphWidgetState extends State<MemoryGraphWidget> {
  final Map<String, MemoryItem?> _memoryCache = {};
  final MemoryRepository _memoryRepo = MemoryRepository();

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void didUpdateWidget(covariant MemoryGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observations != widget.observations) {
      _loadMemories();
    }
  }

  Future<void> _loadMemories() async {
    for (final obs in widget.observations) {
      if (!_memoryCache.containsKey(obs.memoryId)) {
        final mem = await _memoryRepo.getMemoryById(obs.memoryId);
        if (mounted) {
          setState(() {
            _memoryCache[obs.memoryId] = mem;
          });
        }
      }
    }
  }

  void _showEditLocationDialog(BuildContext context, ItemObservation obs) {
    final controller = TextEditingController(text: obs.displayLocation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Correct Sighting Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo Location: ${obs.locationLabel}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Corrected Location / Spot',
                hintText: 'e.g. Study Table, Top Drawer, Backpack',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newLoc = controller.text.trim();
              if (newLoc.isNotEmpty) {
                widget.onLocationCorrected(obs.id, newLoc);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Correction'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter confirmed observations and sort chronologically (oldest to newest)
    final confirmed = widget.observations
        .where((o) => o.userConfirmation == ConfirmationStatus.confirmed)
        .toList()
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

    if (confirmed.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.hub_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No Confirmed Sightings in Memory Graph',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 6),
            const Text(
              'Confirm candidate sightings below to build the chronological visual journey of this item.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timeline, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Memory Graph',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Visual journey of ${widget.itemName} (${confirmed.length} confirmed location hops)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: confirmed.length,
            itemBuilder: (context, index) {
              final obs = confirmed[index];
              final isFirst = index == 0;
              final isLatest = index == confirmed.length - 1;
              final mem = _memoryCache[obs.memoryId];

              String stageLabel;
              Color stageColor;
              if (isLatest) {
                stageLabel = 'Most Recent Observation';
                stageColor = AppColors.success;
              } else if (isFirst) {
                stageLabel = 'First Observed';
                stageColor = AppColors.primary;
              } else {
                stageLabel = 'Later Observed';
                stageColor = AppColors.secondary;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Node & Connecting Line
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: stageColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: stageColor, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              isLatest ? Icons.place : (isFirst ? Icons.flag_outlined : Icons.navigation),
                              size: 14,
                              color: stageColor,
                            ),
                          ),
                        ),
                        if (index < confirmed.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: stageColor.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Observation Details Card
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(bottom: index == confirmed.length - 1 ? 0 : 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLatest
                                ? AppColors.success.withValues(alpha: 0.4)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            if (mem != null && File(mem.thumbnailPath).existsSync())
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailScreen(
                                        memoryId: mem.id,
                                        highlightedObjectId: obs.detectedObjectId,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(mem.thumbnailPath),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: stageColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.photo, color: stageColor, size: 24),
                              ),

                            const SizedBox(width: 12),

                            // Texts and Edit Action
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: stageColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          stageLabel,
                                          style: TextStyle(
                                            color: stageColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 14),
                                        tooltip: 'Correct location',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditLocationDialog(context, obs),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    obs.displayLocation,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (obs.hasManualCorrection)
                                    Text(
                                      'Corrected (Photo: ${obs.locationLabel})',
                                      style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, yyyy • h:mm a').format(obs.observedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
