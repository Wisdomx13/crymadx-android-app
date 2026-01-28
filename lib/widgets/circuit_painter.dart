import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Custom painter for animated circuit board traces
/// Creates paths radiating from a center point with glowing nodes
class CircuitPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0 for path animation
  final double nodeProgress; // 0.0 to 1.0 for node pulse
  final Color circuitColor;
  final double glowIntensity;

  CircuitPainter({
    required this.progress,
    this.nodeProgress = 0.0,
    this.circuitColor = AppColors.circuitGlow,
    this.glowIntensity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Define circuit paths (relative to center, normalized to maxRadius)
    final paths = _getCircuitPaths();

    // Draw each path with animation
    for (final pathData in paths) {
      _drawCircuitPath(
        canvas,
        center,
        maxRadius,
        pathData,
        progress,
        nodeProgress,
      );
    }
  }

  List<_CircuitPath> _getCircuitPaths() {
    return [
      // Top path
      _CircuitPath(
        points: [
          const Offset(0, -0.18),
          const Offset(0, -0.45),
          const Offset(0.12, -0.45),
          const Offset(0.12, -0.62),
        ],
        delay: 0.0,
      ),
      // Top-right path
      _CircuitPath(
        points: [
          const Offset(0.13, -0.13),
          const Offset(0.38, -0.38),
          const Offset(0.55, -0.38),
        ],
        delay: 0.1,
      ),
      // Right path
      _CircuitPath(
        points: [
          const Offset(0.18, 0),
          const Offset(0.48, 0),
          const Offset(0.48, 0.12),
          const Offset(0.62, 0.12),
        ],
        delay: 0.05,
      ),
      // Bottom path
      _CircuitPath(
        points: [
          const Offset(0, 0.18),
          const Offset(0, 0.45),
          const Offset(-0.12, 0.45),
          const Offset(-0.12, 0.62),
        ],
        delay: 0.15,
      ),
      // Bottom-left path
      _CircuitPath(
        points: [
          const Offset(-0.13, 0.13),
          const Offset(-0.38, 0.38),
          const Offset(-0.55, 0.38),
        ],
        delay: 0.08,
      ),
      // Left path
      _CircuitPath(
        points: [
          const Offset(-0.18, 0),
          const Offset(-0.48, 0),
          const Offset(-0.48, -0.12),
          const Offset(-0.62, -0.12),
        ],
        delay: 0.12,
      ),
    ];
  }

  void _drawCircuitPath(
    Canvas canvas,
    Offset center,
    double maxRadius,
    _CircuitPath pathData,
    double progress,
    double nodeProgress,
  ) {
    // Calculate adjusted progress for this path (considering delay)
    final adjustedProgress = ((progress - pathData.delay) / (1 - pathData.delay))
        .clamp(0.0, 1.0);

    if (adjustedProgress <= 0) return;

    // Convert normalized points to actual coordinates
    final points = pathData.points
        .map((p) => Offset(
              center.dx + p.dx * maxRadius,
              center.dy + p.dy * maxRadius,
            ))
        .toList();

    // Create the path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Calculate path metrics for animation
    final pathMetrics = path.computeMetrics().first;
    final animatedLength = pathMetrics.length * adjustedProgress;

    // Extract the animated portion of the path
    final animatedPath = pathMetrics.extractPath(0, animatedLength);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = circuitColor.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(animatedPath, glowPaint);

    // Draw main circuit line
    final linePaint = Paint()
      ..color = circuitColor.withOpacity(0.8 * glowIntensity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(animatedPath, linePaint);

    // Draw nodes at connection points
    if (adjustedProgress > 0) {
      for (int i = 0; i < points.length; i++) {
        // Calculate if this node should be visible
        final nodeThreshold = i / (points.length - 1);
        if (adjustedProgress >= nodeThreshold) {
          final nodeOpacity = math.min(
            1.0,
            (adjustedProgress - nodeThreshold) * 4,
          );

          // Node pulse effect
          final pulseScale = 1.0 + (0.3 * math.sin(nodeProgress * math.pi * 2));

          _drawNode(
            canvas,
            points[i],
            nodeOpacity * glowIntensity,
            pulseScale,
            i == points.length - 1, // End node is larger
          );
        }
      }
    }
  }

  void _drawNode(
    Canvas canvas,
    Offset position,
    double opacity,
    double pulseScale,
    bool isEndNode,
  ) {
    final baseRadius = isEndNode ? 5.0 : 3.0;
    final radius = baseRadius * pulseScale;

    // Outer glow
    final glowPaint = Paint()
      ..color = circuitColor.withOpacity(0.4 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(position, radius * 2, glowPaint);

    // Middle glow
    final midGlowPaint = Paint()
      ..color = circuitColor.withOpacity(0.6 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(position, radius * 1.5, midGlowPaint);

    // Core
    final corePaint = Paint()
      ..color = circuitColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, corePaint);

    // Bright center
    final brightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius * 0.4, brightPaint);
  }

  @override
  bool shouldRepaint(CircuitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.nodeProgress != nodeProgress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class _CircuitPath {
  final List<Offset> points;
  final double delay; // 0.0 to 1.0, when this path starts animating

  _CircuitPath({
    required this.points,
    this.delay = 0.0,
  });
}

/// Widget that displays animated circuit board effect
class CircuitAnimation extends StatefulWidget {
  final double size;
  final Duration duration;
  final Color? color;
  final Widget? child;
  final bool autoStart;

  const CircuitAnimation({
    super.key,
    this.size = 300,
    this.duration = const Duration(milliseconds: 2000),
    this.color,
    this.child,
    this.autoStart = true,
  });

  @override
  State<CircuitAnimation> createState() => _CircuitAnimationState();
}

class _CircuitAnimationState extends State<CircuitAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _pulseController;
  late Animation<double> _pathAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Path animation
    _pathController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _pathAnimation = CurvedAnimation(
      parent: _pathController,
      curve: Curves.easeOutCubic,
    );

    // Pulse animation (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    if (widget.autoStart) {
      _pathController.forward();
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pathAnimation, _pulseAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: CircuitPainter(
              progress: _pathAnimation.value,
              nodeProgress: _pulseAnimation.value,
              circuitColor: widget.color ?? AppColors.circuitGlow,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
