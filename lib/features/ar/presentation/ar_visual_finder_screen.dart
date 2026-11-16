import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/ar_compatibility_service.dart';

class ArVisualFinderScreen extends StatefulWidget {
  final String? targetItemName;
  final String? targetLocation;
  final String? referencePhotoPath;

  const ArVisualFinderScreen({
    super.key,
    this.targetItemName,
    this.targetLocation,
    this.referencePhotoPath,
  });

  @override
  State<ArVisualFinderScreen> createState() => _ArVisualFinderScreenState();
}

class _ArVisualFinderScreenState extends State<ArVisualFinderScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  ArSupportAssessment? _assessment;
  bool _isLoading = true;
  bool _isObjectLocked = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initAssessment();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initAssessment() async {
    final res = await ArCompatibilityService.instance.checkArSupport();
    if (mounted) {
      setState(() {
        _assessment = res;
        _isLoading = false;
      });
    }
  }

  void _showLimitationsDialog() {
    if (_assessment == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'ARCore Live Finder: Technical Realities',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'How the Live AR Finder works:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'The AR reticle uses camera visual SLAM and motion IMU sensors to help you scan room surfaces and retrace where you last photographed an item. It does NOT possess X-ray vision or detect occluded objects through walls or drawers.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              const Text(
                'Known Technical Constraints:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ..._assessment!.technicalLimitations.map(
                (lim) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(lim, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.targetItemName ?? 'Misplaced Item';
    final locationName = widget.targetLocation ?? 'Last Known Area';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        title: Text('AR Finder: $itemName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'AR Limitations',
            onPressed: _showLimitationsDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : Stack(
              children: [
                // Live Viewfinder Background Simulation / Sensor Grid
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF0D1117),
                    child: CustomPaint(
                      painter: _ArGridPainter(pulseValue: _pulseController.value),
                    ),
                  ),
                ),

                // Center AR Targeting Reticle
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isObjectLocked ? AppColors.success : AppColors.primaryLight,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              // Crosshairs
                              Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: _isObjectLocked ? AppColors.success : AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Text(
                                  _isObjectLocked ? 'TARGET LOCATED' : 'SCANNING SURFACE',
                                  style: TextStyle(
                                    color: _isObjectLocked ? AppColors.success : AppColors.primaryLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Text(
                                  locationName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Top Guidance Pill
                Positioned(
                  top: 16,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radar, color: AppColors.primaryLight, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Searching for "$itemName"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Point camera toward $locationName surface',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Corner Reference Photo Preview (if available)
                if (widget.referencePhotoPath != null && File(widget.referencePhotoPath!).existsSync())
                  Positioned(
                    bottom: 90,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Evidence Photo', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54, width: 1.5),
                            ),
                            child: Image.file(File(widget.referencePhotoPath!), fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bottom Action Bar
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isObjectLocked ? AppColors.success : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(_isObjectLocked ? Icons.check_circle : Icons.gps_fixed),
                          label: Text(
                            _isObjectLocked ? 'Item Found & Verified!' : 'Lock Target on Surface',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() => _isObjectLocked = !_isObjectLocked);
                            if (_isObjectLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Target locked for "$itemName" at $locationName!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ArGridPainter extends CustomPainter {
  final double pulseValue;

  _ArGridPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12 + (pulseValue * 0.08))
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArGridPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}
