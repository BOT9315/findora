import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../data/memory_repository.dart';
import '../domain/memory_item.dart';
import '../providers/memory_provider.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  final String memoryId;
  final String? highlightedObjectId;

  const MemoryDetailScreen({
    super.key,
    required this.memoryId,
    this.highlightedObjectId,
  });

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  final MemoryRepository _repository = MemoryRepository();
  MemoryItem? _memory;
  MemoryItem? _prevMemory;
  MemoryItem? _nextMemory;
  bool _isLoading = true;
  bool _showBoundingBoxes = true;

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    setState(() => _isLoading = true);
    final item = await _repository.getMemoryById(widget.memoryId);
    if (item != null) {
      final adjacent = await _repository.getAdjacentMemories(
        memoryId: item.id,
        locationLabel: item.locationLabel,
        capturedAt: item.capturedAt,
      );
      if (mounted) {
        setState(() {
          _memory = item;
          _prevMemory = adjacent['previous'];
          _nextMemory = adjacent['next'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text(
          'This will permanently delete the photograph and its associated AI index records from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await ref.read(memoryListProvider.notifier).deleteMemory(widget.memoryId);
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context); // pop detail screen
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if (_memory == null) return;

    final locationController = TextEditingController(text: _memory!.locationLabel);
    final notesController = TextEditingController(text: _memory!.notes ?? '');
    DateTime editTime = _memory!.capturedAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Memory Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location / Room'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 18),
                  title: Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(editTime),
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: editTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && context.mounted) {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(editTime),
                      );
                      if (t != null) {
                        setDialogState(() {
                          editTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      }
                    }
                  },
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
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(memoryListProvider.notifier).updateMemory(
                      id: _memory!.id,
                      location: locationController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      capturedAt: editTime,
                    );
                await _loadMemory();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_memory == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memory Not Found')),
        body: const Center(child: Text('This memory does not exist or has been deleted.')),
      );
    }

    final file = File(_memory!.imagePath);
    final fallbackFile = File(_memory!.thumbnailPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(_memory!.locationLabel),
        actions: [
          IconButton(
            tooltip: _showBoundingBoxes ? 'Hide Bounding Boxes' : 'Show Bounding Boxes',
            icon: Icon(_showBoundingBoxes ? Icons.layers : Icons.layers_clear),
            onPressed: () => setState(() => _showBoundingBoxes = !_showBoundingBoxes),
          ),
          IconButton(
            tooltip: 'Edit Details',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditDialog,
          ),
          IconButton(
            tooltip: 'Delete Photo',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Zoomable Photo Viewer with Bounding Box Overlays
            Container(
              height: 380,
              width: double.infinity,
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    file.existsSync()
                        ? Image.file(file, fit: BoxFit.contain)
                        : fallbackFile.existsSync()
                            ? Image.file(fallbackFile, fit: BoxFit.contain)
                            : const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 64)),

                    // Bounding Box Overlays
                    if (_showBoundingBoxes)
                      ..._memory!.detectedObjects.where((o) => o.boundingBox != null).map((obj) {
                        final box = obj.boundingBox!;
                        final isTarget = widget.highlightedObjectId != null && obj.id == widget.highlightedObjectId;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            return Positioned(
                              left: box.left * w,
                              top: box.top * h,
                              width: box.width * w,
                              height: box.height * h,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isTarget ? AppColors.warning : AppColors.primaryLight,
                                    width: isTarget ? 3.0 : 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  color: isTarget
                                      ? AppColors.warning.withValues(alpha: 0.25)
                                      : AppColors.primary.withValues(alpha: 0.12),
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    color: isTarget ? AppColors.warning : AppColors.primary,
                                    child: Text(
                                      isTarget
                                          ? 'TARGET: ${obj.label}'
                                          : '${obj.label} (${(obj.confidence * 100).toInt()}%)',
                                      style: TextStyle(
                                        color: isTarget ? Colors.black : Colors.white,
                                        fontSize: isTarget ? 10 : 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Honest AI Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last recorded at ${_memory!.locationLabel} on ${DateFormat('MMM d, yyyy').format(_memory!.capturedAt)}. Current location is not guaranteed.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _memory!.locationLabel,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _memory!.indexingStatus == MemoryIndexingStatus.completed
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _memory!.indexingStatus.displayName,
                          style: TextStyle(
                            color: _memory!.indexingStatus == MemoryIndexingStatus.completed
                                ? AppColors.success
                                : AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('h:mm a • MMM d, yyyy').format(_memory!.capturedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),

                  // Notes section (if any)
                  if (_memory!.notes != null && _memory!.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'User Notes',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Text(
                        _memory!.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Detected Objects & Visual Evidence
                  Text(
                    'Detected Objects (${_memory!.detectedObjects.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_memory!.detectedObjects.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No specific objects detected in this photograph.'),
                    )
                  else
                    ..._memory!.detectedObjects.map((obj) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        obj.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(obj.confidence * 100).toInt()}% confidence',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Color: ${obj.color ?? "detected"} • Spatial: ${obj.spatialQuadrant ?? "in frame"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Room Observation Timeline (Previous & Next Photos in this space)
                  Text(
                    'Room Observations Timeline',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // Previous Observation
                      Expanded(
                        child: _TimelineCard(
                          title: 'Previous Sighting',
                          memory: _prevMemory,
                          isDark: isDark,
                          onTap: _prevMemory == null
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailScreen(memoryId: _prevMemory!.id),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next Observation
                      Expanded(
                        child: _TimelineCard(
                          title: 'Subsequent Sighting',
                          memory: _nextMemory,
                          isDark: isDark,
                          onTap: _nextMemory == null
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => MemoryDetailScreen(memoryId: _nextMemory!.id),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String title;
  final MemoryItem? memory;
  final bool isDark;
  final VoidCallback? onTap;

  const _TimelineCard({
    required this.title,
    required this.memory,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (memory == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 6),
            const Text('None recorded', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final file = File(memory!.thumbnailPath);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade800,
              ),
              clipBehavior: Clip.antiAlias,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Icon(Icons.photo, size: 20, color: Colors.white70),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(memory!.capturedAt),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
