import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Glass overlay variant types
enum GlassOverlayVariant {
  dark,     // Heavy tint (0.75 opacity)
  medium,   // Medium tint (0.55 opacity)
  light,    // Light tint (0.35 opacity)
  luxury,   // Green-tinted premium feel
  liquid,   // Smooth liquid dark feel
}

/// A premium glassmorphism overlay widget that provides consistent
/// liquid glass effects across the app
class GlassOverlay extends StatelessWidget {
  final Widget child;
  final GlassOverlayVariant variant;
  final double blur;
  final double? borderRadius;
  final bool showReflection;
  final bool showInnerGlow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassOverlay({
    super.key,
    required this.child,
    this.variant = GlassOverlayVariant.dark,
    this.blur = 16.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  /// Dark variant - heavy tint
  const GlassOverlay.dark({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : variant = GlassOverlayVariant.dark;

  /// Medium variant
  const GlassOverlay.medium({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : variant = GlassOverlayVariant.medium;

  /// Light variant
  const GlassOverlay.light({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : variant = GlassOverlayVariant.light;

  /// Luxury variant - green-tinted premium
  const GlassOverlay.luxury({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : variant = GlassOverlayVariant.luxury;

  /// Liquid variant - smooth liquid dark
  const GlassOverlay.liquid({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.showReflection = true,
    this.showInnerGlow = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  }) : variant = GlassOverlayVariant.liquid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? 20.0;
    final config = _getVariantConfig(isDark);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: config.gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: config.borderColor,
              width: 1.0,
            ),
            boxShadow: config.shadows,
          ),
          child: Stack(
            children: [
              // Top reflection line
              if (showReflection && isDark)
                Positioned(
                  top: 0,
                  left: radius,
                  right: radius,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(config.reflectionOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Inner glow (top-left corner)
              if (showInnerGlow && isDark)
                Positioned(
                  top: 10,
                  left: 15,
                  child: Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          config.innerGlowColor,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),

              // Main content
              child,
            ],
          ),
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }

  _GlassConfig _getVariantConfig(bool isDark) {
    if (!isDark) {
      // Light mode - simpler styling
      return _GlassConfig(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderColor: Colors.grey[300]!,
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        reflectionOpacity: 0.0,
        innerGlowColor: Colors.transparent,
      );
    }

    switch (variant) {
      case GlassOverlayVariant.dark:
        return _GlassConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.75),
              Colors.black.withOpacity(0.85),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.08),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          reflectionOpacity: 0.15,
          innerGlowColor: Colors.white.withOpacity(0.05),
        );

      case GlassOverlayVariant.medium:
        return _GlassConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.black.withOpacity(0.65),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.12),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          reflectionOpacity: 0.18,
          innerGlowColor: Colors.white.withOpacity(0.06),
        );

      case GlassOverlayVariant.light:
        return _GlassConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.35),
              Colors.black.withOpacity(0.45),
            ],
          ),
          borderColor: Colors.white.withOpacity(0.15),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          reflectionOpacity: 0.2,
          innerGlowColor: Colors.white.withOpacity(0.08),
        );

      case GlassOverlayVariant.luxury:
        return _GlassConfig(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.premiumSurface,
              Colors.black.withOpacity(0.9),
            ],
          ),
          borderColor: AppColors.premiumBorder,
          shadows: [
            BoxShadow(
              color: AppColors.premiumGlow,
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          reflectionOpacity: 0.12,
          innerGlowColor: AppColors.premiumHighlight,
        );

      case GlassOverlayVariant.liquid:
        return _GlassConfig(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.liquidGradientStart,
              AppColors.liquidGradientEnd,
            ],
          ),
          borderColor: AppColors.liquidReflection,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          reflectionOpacity: 0.1,
          innerGlowColor: Colors.white.withOpacity(0.04),
        );
    }
  }
}

class _GlassConfig {
  final Gradient gradient;
  final Color borderColor;
  final List<BoxShadow> shadows;
  final double reflectionOpacity;
  final Color innerGlowColor;

  _GlassConfig({
    required this.gradient,
    required this.borderColor,
    required this.shadows,
    required this.reflectionOpacity,
    required this.innerGlowColor,
  });
}
