import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../ar/presentation/ar_visual_finder_screen.dart';
import '../../memories/presentation/memory_detail_screen.dart';
import '../data/items_repository.dart';
import '../domain/item_identity.dart';
import '../domain/item_observation.dart';
import '../providers/items_provider.dart';
import 'memory_graph_widget.dart';

class ItemHistoryScreen extends ConsumerStatefulWidget {
  final ItemIdentity item;

  const ItemHistoryScreen({super.key, required this.item});

  @override
  ConsumerState<ItemHistoryScreen> createState() => _ItemHistoryScreenState();
}

class _ItemHistoryScreenState extends ConsumerState<ItemHistoryScreen> {
  late ItemIdentity _item;
  List<ItemObservation> _observations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadObservations();
  }

  Future<void> _loadObservations() async {
    setState(() => _isLoading = true);
    final obs = await ref.read(itemsProvider.notifier).getObservationsForItem(_item.id);
    if (mounted) {
      setState(() {
        _observations = obs;
        _isLoading = false;
      });
    }
  }

  void _changeStatus(ItemStatus newStatus) async {
    setState(() {
      _item = _item.copyWith(status: newStatus);
    });
    await ref.read(itemsProvider.notifier).updateItemStatus(_item.id, newStatus);
  }

  Future<void> _scanMatches() async {
    setState(() => _isLoading = true);
    final obs = await ref.read(itemsProvider.notifier).scanForPotentialMatches(_item.id);
    if (mounted) {
      setState(() {
        _observations = obs;
        _isLoading = false;
      });
      final pendingCount = _observations.where((o) => o.userConfirmation == ConfirmationStatus.pending).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned memories. $pendingCount potential matches ready for review.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar, color: AppColors.primary),
            tooltip: 'Locate in AR',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArVisualFinderScreen(
                    targetItemName: _item.name,
                    targetLocation: _item.lastObservedLocation,
                    referencePhotoPath: _item.referencePhotoPath,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.saved_search),
            tooltip: 'Scan for candidate sightings',
            onPressed: _scanMatches,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Overview Card
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _item.category,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (_item.referencePhotoPath != null && File(_item.referencePhotoPath!).existsSync()) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_item.referencePhotoPath!),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  if (_item.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _item.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Current Item State Selector
                  Text(
                    'Item Status State',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ItemStatus.values.map((status) {
                      final isSelected = _item.status == status;
                      return ChoiceChip(
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) _changeStatus(status);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Honest Reasoning Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Observations show when this item was photographed. If it is absent from later photos, do not infer it was moved unless you personally confirmed it.',
                      style: TextStyle(fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Personal Memory Graph (Visual Journey of Belonging)
            MemoryGraphWidget(
              itemName: _item.name,
              observations: _observations,
              onLocationCorrected: (obsId, newLoc) async {
                await ref.read(itemsProvider.notifier).updateObservationLocation(obsId, newLoc);
                await _loadObservations();
                final updatedItem = await ItemsRepository().getItemById(_item.id);
                if (updatedItem != null && mounted) {
                  setState(() => _item = updatedItem);
                }
              },
            ),

            const SizedBox(height: 24),

            // Pending Candidate Sightings Section (Uncertain, awaiting user confirmation)
            if (_observations.any((o) => o.userConfirmation == ConfirmationStatus.pending)) ...[
              Row(
                children: [
                  const Icon(Icons.help_outline, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Candidate Sightings to Review (${_observations.where((o) => o.userConfirmation == ConfirmationStatus.pending).length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Visually detected candidates. Confirm if this is genuinely your item, or reject if it is a different object.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ..._observations
                  .where((o) => o.userConfirmation == ConfirmationStatus.pending)
                  .map((obs) => _ObservationCard(
                        observation: obs,
                        isDark: isDark,
                        onConfirmMatch: (confirmed) async {
                          final status = confirmed ? ConfirmationStatus.confirmed : ConfirmationStatus.rejected;
                          await ref.read(itemsProvider.notifier).confirmObservation(obs.id, status);
                          await _loadObservations();
                          final updated = await ItemsRepository().getItemById(_item.id);
                          if (updated != null && mounted) {
                            setState(() => _item = updated);
                          }
                        },
                      )),
              const SizedBox(height: 20),
            ],

            // Complete Sightings History Log
            Text(
              'Complete Sightings History (${_observations.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_observations.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No sightings recorded yet for this item.'),
                ),
              )
            else
              ..._observations.map((obs) {
                return _ObservationCard(
                  observation: obs,
                  isDark: isDark,
                  onConfirmMatch: (confirmed) async {
                    final status = confirmed ? ConfirmationStatus.confirmed : ConfirmationStatus.rejected;
                    await ref.read(itemsProvider.notifier).confirmObservation(obs.id, status);
                    await _loadObservations();
                    final updated = await ItemsRepository().getItemById(_item.id);
                    if (updated != null && mounted) {
                      setState(() => _item = updated);
                    }
                  },
                );
              }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final ItemObservation observation;
  final bool isDark;
  final Function(bool confirmed) onConfirmMatch;

  const _ObservationCard({
    required this.observation,
    required this.isDark,
    required this.onConfirmMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.displayLocation,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (observation.hasManualCorrection)
                      Text(
                        'Corrected (Photo: ${observation.locationLabel})',
                        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
                      ),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy • h:mm a').format(observation.observedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(observation.matchConfidence * 100).toInt()}% conf',
                  style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Match status: ${observation.userConfirmation.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: observation.userConfirmation == ConfirmationStatus.confirmed
                      ? AppColors.success
                      : observation.userConfirmation == ConfirmationStatus.rejected
                          ? AppColors.danger
                          : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (observation.userConfirmation == ConfirmationStatus.pending) ...[
                TextButton(
                  onPressed: () => onConfirmMatch(false),
                  child: const Text('Reject', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => onConfirmMatch(true),
                  child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.image_outlined, size: 16),
            label: const Text('View Source Photo', style: TextStyle(fontSize: 12)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MemoryDetailScreen(memoryId: observation.memoryId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
