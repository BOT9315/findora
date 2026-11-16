import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../ai/presentation/findora_scanning_hud.dart';
import '../providers/capture_controller.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final bool autoStartCamera;
  final bool autoStartGallery;

  const CaptureScreen({
    super.key,
    this.autoStartCamera = false,
    this.autoStartGallery = false,
  });

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customLocationController = TextEditingController();
  bool _isCustomLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoStartCamera) {
        ref.read(captureProvider.notifier).pickFromCamera();
      } else if (widget.autoStartGallery) {
        ref.read(captureProvider.notifier).pickFromGallery();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final current = ref.read(captureProvider).capturedAt;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(minutes: 5)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );

      if (pickedTime != null && mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        ref.read(captureProvider.notifier).setCapturedAt(newDateTime);
      }
    }
  }

  void _savePhoto() async {
    final notifier = ref.read(captureProvider.notifier);
    if (_isCustomLocation && _customLocationController.text.trim().isNotEmpty) {
      notifier.setLocation(_customLocationController.text.trim());
    }
    notifier.setNotes(_notesController.text.trim());

    final saved = await notifier.saveAndIndex();
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo saved! Visual indexing in progress.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture for Findora'),
        actions: [
          if (state.selectedFile != null)
            TextButton(
              onPressed: state.isBusy ? null : _savePhoto,
              child: state.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error Message (if any)
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Image Preview or Picker Buttons
            if (state.selectedFile == null)
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 56,
                      color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take a photo of your space or objects',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Desk, shelves, backpack, drawer, or room',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => ref.read(captureProvider.notifier).pickFromCamera(),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => ref.read(captureProvider.notifier).pickFromGallery(),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            state.selectedFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // FINDORA AI Scanning HUD Overlay
                        FindoraScanningHud(
                          isScanning: state.isBusy,
                          statusText: 'FINDORA Neural Vision Indexing: ${state.locationLabel}...',
                          detectedObjects: [state.locationLabel],
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              tooltip: 'Retake photo',
                              onPressed: () => ref.read(captureProvider.notifier).clearSelection(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => ref.read(captureProvider.notifier).pickFromCamera(),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Retake with Camera'),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.read(captureProvider.notifier).pickFromGallery(),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Choose Another'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Observational Truth: Records last-seen visual evidence. Does not guarantee current location if moved after capture.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Location / Room Label
            Text(
              'Location / Room Label',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...AppConstants.defaultLocations.map((loc) {
                  final isSelected = !_isCustomLocation && state.locationLabel == loc;
                  return ChoiceChip(
                    label: Text(loc),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _isCustomLocation = false);
                        ref.read(captureProvider.notifier).setLocation(loc);
                      }
                    },
                  );
                }),
                ChoiceChip(
                  label: const Text('Custom...'),
                  selected: _isCustomLocation,
                  onSelected: (selected) {
                    setState(() => _isCustomLocation = true);
                  },
                ),
              ],
            ),

            if (_isCustomLocation) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customLocationController,
                decoration: const InputDecoration(
                  labelText: 'Custom Location / Space',
                  hintText: 'e.g. Gym Locker, Lab Shelf 4, Car Trunk',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Observation Timestamp
            Text(
              'Observation Timestamp',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceHighlight : AppColors.lightSurfaceHighlight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEE, MMM d, yyyy • h:mm a').format(state.capturedAt),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Optional Notes
            Text(
              'Optional Notes & Search Clues',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Put college ID card next to black charger and keys before leaving for class.',
              ),
            ),

            const SizedBox(height: 32),

            // Save & Index Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: state.isBusy || state.selectedFile == null ? null : _savePhoto,
                icon: state.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  state.isBusy ? 'Saving & Indexing...' : 'Save & Index Memory',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
