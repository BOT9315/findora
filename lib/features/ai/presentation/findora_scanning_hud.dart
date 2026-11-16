import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// FINDORA AI Scanning HUD Overlay
/// Renders an animated laser sweep line, rotating orbital scanning rings,
/// glowing object detection brackets, and dynamic neural status telemetry.
class FindoraScanningHud extends StatefulWidget {
  final bool isScanning;
  final String statusText;
  final List<String> detectedObjects;

  const FindoraScanningHud({
    super.key,
    required this.isScanning,
    this.statusText = 'FINDORA Neural Vision Indexing...',
    this.detectedObjects = const [],
  });

  @override
  State<FindoraScanningHud> createState() => _FindoraScanningHudState();
}

class _FindoraScanningHudState extends State<FindoraScanningHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) return const SizedBox.shrink();

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scanY = _controller.value;
          final rotation = _controller.value * 2 * math.pi;

          return Stack(
            children: [
              // 1. Cyber scanner laser line & gradient beam
              Positioned.fill(
                child: CustomPaint(
                  painter: _LaserScanPainter(
                    scanProgress: scanY,
                    rotation: rotation,
                  ),
                ),
              ),

              // 2. Corner Bracket Targeting Reticle
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _CornerBracketsPainter(),
                ),
              ),

              // 3. AI Status Badge at Top
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI ACTIVE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Detected Objects Overlay Pills
              if (widget.detectedObjects.isNotEmpty)
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.detectedObjects.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 12, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LaserScanPainter extends CustomPainter {
  final double scanProgress;
  final double rotation;

  _LaserScanPainter({required this.scanProgress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * scanProgress;

    // Laser gradient trail
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromLTWH(0, y - 50, size.width, 50));
    canvas.drawRect(Rect.fromLTWH(0, y - 50, size.width, 50), trailPaint);

    // Sharp glowing scan line
    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.0;
    final lineGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.7)
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(Offset(0, y), Offset(size.width, y), lineGlow);
    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    // Center rotating scanning crosshair
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final reticlePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, 36, reticlePaint);

    // Radial tick lines
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * math.pi;
      canvas.drawLine(
        Offset(36 * math.cos(angle), 36 * math.sin(angle)),
        Offset(46 * math.cos(angle), 46 * math.sin(angle)),
        reticlePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaserScanPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress || oldDelegate.rotation != rotation;
  }
}

class _CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const arm = 18.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(arm, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, arm), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - arm, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, arm), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(arm, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - arm), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - arm, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
