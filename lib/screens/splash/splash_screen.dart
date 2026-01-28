import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../theme/colors.dart';

/// Splash Screen - Logo first, then subtle circuits animate around it
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _circuitController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _textController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _circuitAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation - starts IMMEDIATELY (0-800ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Circuit animation - starts AFTER logo appears (delayed)
    _circuitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _circuitAnimation = CurvedAnimation(
      parent: _circuitController,
      curve: Curves.easeOutCubic,
    );

    // Pulse animation for circuit nodes (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pulseController);

    // Glow animation for logo
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Text animation - appears after circuits start
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Animation sequence:
    // 1. Logo appears immediately
    _logoController.forward();
    _glowController.repeat(reverse: true);

    // 2. Circuits animate after logo is visible (600ms delay)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _circuitController.forward();
        _pulseController.repeat();
      }
    });

    // 3. Text appears after circuits start (900ms delay)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _circuitController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Subtle circuits around the logo (appears after logo)
            AnimatedBuilder(
              animation: Listenable.merge([_circuitAnimation, _pulseAnimation]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width * 0.7, size.width * 0.7),
                  painter: _SubtleCircuitPainter(
                    progress: _circuitAnimation.value,
                    pulseProgress: _pulseAnimation.value,
                  ),
                );
              },
            ),

            // Logo with glass container (appears FIRST)
            AnimatedBuilder(
              animation: Listenable.merge([_logoController, _glowController]),
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: _buildGlassLogo(),
                  ),
                );
              },
            ),

            // App name below logo
            Positioned(
              bottom: size.height * 0.15,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'CRYMADX',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Trade Smarter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primary.withOpacity(0.8),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassLogo() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Outer glow - white instead of green
              BoxShadow(
                color: Colors.white.withOpacity(0.15 * _glowAnimation.value),
                blurRadius: 40,
                spreadRadius: 5,
              ),
              // Inner shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                      Colors.black.withOpacity(0.2),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top reflection
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Inner highlight
                    Positioned(
                      top: 10,
                      left: 15,
                      child: Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback logo
                          return Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                'C',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Subtle circuit painter - draws small elegant circuits around the logo
class _SubtleCircuitPainter extends CustomPainter {
  final double progress;
  final double pulseProgress;

  _SubtleCircuitPainter({
    required this.progress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final logoRadius = size.width * 0.22; // Logo boundary
    final maxRadius = size.width / 2;

    // Define 4 subtle circuit paths around the logo
    final paths = [
      // Top-left circuit
      _CircuitPath(
        startAngle: 135,
        points: [0.28, 0.35, 0.42],
        delay: 0.0,
      ),
      // Top-right circuit
      _CircuitPath(
        startAngle: 45,
        points: [0.28, 0.38, 0.45],
        delay: 0.15,
      ),
      // Bottom-right circuit
      _CircuitPath(
        startAngle: -45,
        points: [0.28, 0.33, 0.40],
        delay: 0.1,
      ),
      // Bottom-left circuit
      _CircuitPath(
        startAngle: -135,
        points: [0.28, 0.36, 0.43],
        delay: 0.2,
      ),
    ];

    for (final pathData in paths) {
      _drawCircuitPath(canvas, center, maxRadius, pathData);
    }
  }

  void _drawCircuitPath(
    Canvas canvas,
    Offset center,
    double maxRadius,
    _CircuitPath pathData,
  ) {
    // Adjust progress for delay
    final adjustedProgress = ((progress - pathData.delay) / (1 - pathData.delay))
        .clamp(0.0, 1.0);

    if (adjustedProgress <= 0) return;

    final angleRad = pathData.startAngle * math.pi / 180;

    // Calculate points along the path
    final points = <Offset>[];
    for (int i = 0; i < pathData.points.length; i++) {
      final distance = pathData.points[i] * maxRadius;
      // Add slight angle variation for each point
      final angle = angleRad + (i * 0.1);
      points.add(Offset(
        center.dx + math.cos(angle) * distance,
        center.dy + math.sin(angle) * distance,
      ));
    }

    // Create the path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Calculate animated length
    final pathMetrics = path.computeMetrics().first;
    final animatedLength = pathMetrics.length * adjustedProgress;
    final animatedPath = pathMetrics.extractPath(0, animatedLength);

    // Draw subtle glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15 * adjustedProgress)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawPath(animatedPath, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.4 * adjustedProgress)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(animatedPath, linePaint);

    // Draw nodes at points
    for (int i = 0; i < points.length; i++) {
      final nodeThreshold = i / (points.length - 1);
      if (adjustedProgress >= nodeThreshold) {
        final nodeOpacity = ((adjustedProgress - nodeThreshold) * 3).clamp(0.0, 1.0);
        final pulseScale = 1.0 + (0.2 * math.sin(pulseProgress * math.pi * 2));

        _drawNode(canvas, points[i], nodeOpacity, pulseScale, i == points.length - 1);
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
    final baseRadius = isEndNode ? 3.0 : 2.0;
    final radius = baseRadius * pulseScale;

    // Outer glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, radius * 2, glowPaint);

    // Core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, corePaint);

    // Bright center
    final brightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius * 0.4, brightPaint);
  }

  @override
  bool shouldRepaint(_SubtleCircuitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

class _CircuitPath {
  final double startAngle; // Angle from center in degrees
  final List<double> points; // Distance from center as fraction of maxRadius
  final double delay;

  _CircuitPath({
    required this.startAngle,
    required this.points,
    this.delay = 0.0,
  });
}
