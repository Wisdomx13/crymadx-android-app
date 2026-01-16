import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Glass Card variant types
enum GlassCardVariant {
  /// Default glass card
  defaultCard,

  /// Elevated with more prominence
  elevated,

  /// Most prominent with glow effect
  prominent,

  /// Subtle, barely visible
  subtle,
}

/// GlassCard - Glassmorphism card widget matching CrymadX design
class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final bool showGlow;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.defaultCard,
    this.padding,
    this.showGlow = false,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardPadding = padding ?? const EdgeInsets.all(AppSpacing.md);
    final cardRadius = borderRadius ?? BorderRadius.circular(AppRadius.card);

    // Get variant-specific styles
    final (backgroundColor, borderColor, shadowColor) = _getVariantStyles(isDark);

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: cardRadius,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: isDark
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: cardPadding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientCardShine,
                    ),
                  ),
                  child: child,
                ),
              )
            : Container(
                padding: cardPadding,
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  (Color, Color, Color) _getVariantStyles(bool isDark) {
    if (isDark) {
      switch (variant) {
        case GlassCardVariant.elevated:
          return (
            AppColors.backgroundElevated,
            AppColors.glassBorderLight,
            AppColors.glassGlow,
          );
        case GlassCardVariant.prominent:
          return (
            AppColors.backgroundCard,
            AppColors.glassBorderAccent,
            AppColors.glassGlow,
          );
        case GlassCardVariant.subtle:
          return (
            AppColors.backgroundContainer,
            AppColors.glassSubtle,
            Colors.transparent,
          );
        case GlassCardVariant.defaultCard:
        default:
          return (
            AppColors.backgroundCard,
            AppColors.glassBorder,
            Colors.transparent,
          );
      }
    } else {
      // Light theme colors
      switch (variant) {
        case GlassCardVariant.elevated:
          return (
            AppColors.lightBackgroundElevated,
            AppColors.lightGlassBorderLight,
            AppColors.lightGlassGlow,
          );
        case GlassCardVariant.prominent:
          return (
            AppColors.lightBackgroundCard,
            AppColors.lightGlassBorderAccent,
            AppColors.lightGlassGlow,
          );
        case GlassCardVariant.subtle:
          return (
            AppColors.lightBackgroundContainer,
            AppColors.lightGlassSubtle,
            Colors.transparent,
          );
        case GlassCardVariant.defaultCard:
        default:
          return (
            AppColors.lightBackgroundCard,
            AppColors.lightGlassBorder,
            Colors.transparent,
          );
      }
    }
  }
}

/// Simple glass surface without card styling
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 10,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: color ?? AppColors.glassFrosted,
          child: child,
        ),
      ),
    );
  }
}
