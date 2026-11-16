import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/findora_orbit_logo.dart';

/// FINDORA Custom Animated Splash Screen
/// Implements the exact 8-step animation sequence:
/// 1. Dark midnight-purple screen
/// 2. Glowing cyan particle in the center
/// 3. Purple & blue orbital rings form
/// 4. AI neural connections illuminate
/// 5. FINDORA logo emerges with glow
/// 6. Bold FINDORA typography
/// 7. "Never Lose What Matters." tagline
/// 8. "Created & Developed by Ankush" developer credit
class FindoraSplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const FindoraSplashScreen({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<FindoraSplashScreen> createState() => _FindoraSplashScreenState();
}

class _FindoraSplashScreenState extends State<FindoraSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _particleScale;
  late Animation<double> _orbitProgress;
  late Animation<double> _neuralProgress;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _creditFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 1 & 2: Glowing cyan particle (0.0 -> 0.3)
    _particleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.30, curve: Curves.easeOutBack),
      ),
    );

    // 3: Orbital rings form (0.25 -> 0.55)
    _orbitProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeInOutCubic),
      ),
    );

    // 4: AI neural connections illuminate (0.45 -> 0.70)
    _neuralProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.70, curve: Curves.easeInQuad),
      ),
    );

    // 5: Logo emerges with smooth glow (0.60 -> 0.85)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    // 6 & 7: Typography & Tagline (0.70 -> 0.92)
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.92, curve: Curves.easeOut),
      ),
    );

    // 8: Developer credit (0.80 -> 1.0)
    _creditFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onAnimationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    _controller.stop();
    widget.onAnimationComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Stack(
          children: [
            // Deep midnight purple & radial cyber gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1B1238), // Deep vibrant midnight purple
                    Color(0xFF0F0B24),
                    Color(0xFF080811), // Midnight Black
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Animated particle & orbit canvas
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _SplashParticleOrbitPainter(
                    particleScale: _particleScale.value,
                    orbitProgress: _orbitProgress.value,
                    neuralProgress: _neuralProgress.value,
                    time: _controller.value * 2 * math.pi,
                  ),
                );
              },
            ),

            // Center Content: Logo, Title, Tagline
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo emergence (0.60 -> 0.85)
                    AnimatedBuilder(
                      animation: _logoFade,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: 0.85 + 0.15 * _logoFade.value,
                            child: const FindoraOrbitLogo(
                              size: 140,
                              animate: true,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bold Typography "FINDORA" & Tagline (0.70 -> 0.92)
                    AnimatedBuilder(
                      animation: _textFade,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - _textFade.value)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'F I N D O R A',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 6,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: AppColors.primary.withValues(alpha: 0.8),
                                            blurRadius: 18,
                                          ),
                                          Shadow(
                                            color: AppColors.accent.withValues(alpha: 0.6),
                                            blurRadius: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppConstants.tagLine,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 4),

                    // Step 8: Bottom Developer Credit
                    AnimatedBuilder(
                      animation: _creditFade,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _creditFade.value,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        size: 13,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppConstants.developerCredit,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to skip',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.darkTextTertiary.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashParticleOrbitPainter extends CustomPainter {
  final double particleScale;
  final double orbitProgress;
  final double neuralProgress;
  final double time;

  _SplashParticleOrbitPainter({
    required this.particleScale,
    required this.orbitProgress,
    required this.neuralProgress,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.40);

    // 1. Ambient Background Particles
    final rnd = math.Random(42);
    final bgParticlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 30; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 1.0 + rnd.nextDouble() * 2.0;
      final alpha = (0.2 + 0.3 * math.sin(time + i)) * (1.0 - math.exp(-particleScale * 3));
      bgParticlePaint.color = (i % 2 == 0 ? AppColors.accent : AppColors.primaryLight)
          .withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), r, bgParticlePaint);
    }

    // 2. Central glowing cyan particle (Phase 1 & 2)
    if (particleScale > 0) {
      final cyanGlowPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: (0.7 * particleScale).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * particleScale);
      canvas.drawCircle(center, 18 * particleScale, cyanGlowPaint);

      final cyanCorePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6 * particleScale, cyanCorePaint);
    }

    // 3. Purple and blue orbital rings expanding & rotating (Phase 3)
    if (orbitProgress > 0) {
      final ringPaint1 = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.6 * orbitProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final ringPaint2 = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.5 * orbitProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final maxR1 = 110.0 * orbitProgress;
      final maxR2 = 85.0 * orbitProgress;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(time * 0.6);
      canvas.drawCircle(Offset.zero, maxR1, ringPaint1);

      // Dash ticks on outer ring
      final tickPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.7 * orbitProgress)
        ..strokeWidth = 2;
      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * 2 * math.pi;
        canvas.drawLine(
          Offset(maxR1 * math.cos(angle), maxR1 * math.sin(angle)),
          Offset((maxR1 + 6) * math.cos(angle), (maxR1 + 6) * math.sin(angle)),
          tickPaint,
        );
      }
      canvas.restore();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-time * 0.9);
      canvas.drawCircle(Offset.zero, maxR2, ringPaint2);
      canvas.restore();
    }

    // 4. AI neural synaptic lines illuminating (Phase 4)
    if (neuralProgress > 0) {
      final synLinePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.65 * neuralProgress)
        ..strokeWidth = 1.4;

      final nodePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      const numNodes = 7;
      final nodeRadius = 90.0 * orbitProgress;
      for (int i = 0; i < numNodes; i++) {
        final angle = (i / numNodes) * 2 * math.pi + (time * 0.3);
        final nodePos = center + Offset(nodeRadius * math.cos(angle), nodeRadius * math.sin(angle));

        // Connect center to orbital node
        canvas.drawLine(center, nodePos, synLinePaint);

        // Connect adjacent nodes
        if (i > 0) {
          final prevAngle = ((i - 1) / numNodes) * 2 * math.pi + (time * 0.3);
          final prevNode = center + Offset(nodeRadius * math.cos(prevAngle), nodeRadius * math.sin(prevAngle));
          canvas.drawLine(prevNode, nodePos, synLinePaint);
        }

        canvas.drawCircle(nodePos, 3.5 * neuralProgress, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticleOrbitPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.particleScale != particleScale ||
        oldDelegate.orbitProgress != orbitProgress ||
        oldDelegate.neuralProgress != neuralProgress;
  }
}
