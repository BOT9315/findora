import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// FINDORA ORBIT – Custom Futuristic Logo Widget
/// Renders an intelligent circular tracking ring, a glowing futuristic location orb,
/// AI neural-network node connections, and a glowing object silhouette.
class FindoraOrbitLogo extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showAssetImageIfAvailable;

  const FindoraOrbitLogo({
    super.key,
    this.size = 120,
    this.animate = true,
    this.showAssetImageIfAvailable = true,
  });

  @override
  State<FindoraOrbitLogo> createState() => _FindoraOrbitLogoState();
}

class _FindoraOrbitLogoState extends State<FindoraOrbitLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _FindoraOrbitPainter(
              rotation: _controller.value * 2 * math.pi,
              pulse: (math.sin(_controller.value * 2 * math.pi) + 1) / 2,
            ),
          );
        },
      ),
    );
  }
}

class _FindoraOrbitPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _FindoraOrbitPainter({
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Ambient outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.35 + 0.15 * pulse),
          AppColors.accent.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));
    canvas.drawCircle(center, radius * 1.1, glowPaint);

    // 2. Outer Orbital Ring 1 (Electric Violet, slightly tilted & rotating)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final orbitPaint1 = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022;

    // Draw dashed orbital ring
    const segments = 24;
    final orbitRadius = radius * 0.86;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        final startAngle = (i / segments) * 2 * math.pi;
        final sweepAngle = (0.7 / segments) * 2 * math.pi;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: orbitRadius),
          startAngle,
          sweepAngle,
          false,
          orbitPaint1,
        );
      }
    }

    // Tracking beacon node on outer orbit
    final beaconPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(orbitRadius, 0), size.width * 0.035, beaconPaint);

    // Beacon glow
    final beaconGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(orbitRadius, 0), size.width * 0.05, beaconGlow);
    canvas.restore();

    // 3. Counter-rotating inner tracking orbit (Cyan)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotation * 0.8);

    final orbitPaint2 = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.016;

    final innerOrbitRadius = radius * 0.70;
    canvas.drawCircle(Offset.zero, innerOrbitRadius, orbitPaint2);

    // Data ticks
    final tickPaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final p1 = Offset(innerOrbitRadius * math.cos(angle), innerOrbitRadius * math.sin(angle));
      final p2 = Offset((innerOrbitRadius - 4) * math.cos(angle), (innerOrbitRadius - 4) * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
    canvas.restore();

    // 4. Central Futuristic Orb (Deep Royal Purple to Electric Violet Gradient)
    final orbRadius = radius * 0.50;
    final orbGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: [
        AppColors.neonGlow,
        AppColors.primary,
        AppColors.primaryDark,
        const Color(0xFF0D0B1F),
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );

    final orbPaint = Paint()
      ..shader = orbGradient.createShader(Rect.fromCircle(center: center, radius: orbRadius));
    canvas.drawCircle(center, orbRadius, orbPaint);

    // Orb rim highlight
    final orbRimPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.018;
    canvas.drawCircle(center, orbRadius, orbRimPaint);

    // 5. AI Neural Network Nodes & Connections inside the orb
    final nodePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.45 + 0.25 * pulse)
      ..strokeWidth = 1.2;

    final nodes = [
      center + Offset(-orbRadius * 0.4, -orbRadius * 0.3),
      center + Offset(orbRadius * 0.45, -orbRadius * 0.25),
      center + Offset(-orbRadius * 0.35, orbRadius * 0.4),
      center + Offset(orbRadius * 0.38, orbRadius * 0.35),
      center + Offset(0, -orbRadius * 0.55),
    ];

    // Connect neural synaptic lines
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawLine(center, nodes[i], linePaint);
      if (i > 0) canvas.drawLine(nodes[i - 1], nodes[i], linePaint);
      canvas.drawCircle(nodes[i], size.width * 0.016, nodePaint);
    }

    // 6. Center Object Silhouette (Futuristic Locator Beacon & Key Core)
    final coreGlow = Paint()
      ..color = AppColors.accent
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 3 * pulse);
    canvas.drawCircle(center, size.width * 0.065, coreGlow);

    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.038, corePaint);

    // Tiny holographic pin stem
    final pinPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, center + Offset(0, size.width * 0.075), pinPaint);
  }

  @override
  bool shouldRepaint(covariant _FindoraOrbitPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
  }
}
