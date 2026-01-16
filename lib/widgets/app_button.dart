import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'glass_card.dart';

/// Alias for GlassCardVariant for backward compatibility
typedef GlassVariant = GlassCardVariant;

/// Button variant types
enum AppButtonVariant {
  /// Primary filled button with gradient
  primary,

  /// Secondary filled button
  secondary,

  /// Outlined button
  outline,

  /// Ghost/text button
  ghost,

  /// Buy/success button
  buy,

  /// Sell/danger button
  sell,
}

/// Alias for AppButtonVariant for backward compatibility
typedef ButtonVariant = AppButtonVariant;

/// Button size options
enum AppButtonSize {
  small,
  medium,
  large,
}

/// AppButton - Custom button matching CrymadX design
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final IconData? icon; // Alias for leftIcon
  final bool disabled;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leftIcon,
    this.rightIcon,
    this.icon,
    this.disabled = false,
  });

  /// Get effective left icon (icon parameter takes precedence if leftIcon is null)
  IconData? get effectiveLeftIcon => leftIcon ?? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || isLoading || onPressed == null;
    final (height, fontSize, iconSize, horizontalPadding) = _getSizeStyles();
    final (bgColor, textColor, borderColor) = _getVariantStyles();

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (effectiveLeftIcon != null) ...[
          Icon(effectiveLeftIcon, size: iconSize, color: textColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (rightIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(rightIcon, size: iconSize, color: textColor),
        ],
      ],
    );

    // Build button based on variant
    if (variant == AppButtonVariant.primary) {
      return _buildGradientButton(
        content: content,
        height: height,
        horizontalPadding: horizontalPadding,
        isDisabled: isDisabled,
      );
    }

    if (variant == AppButtonVariant.outline) {
      return _buildOutlineButton(
        content: content,
        height: height,
        horizontalPadding: horizontalPadding,
        borderColor: borderColor,
        textColor: textColor,
        isDisabled: isDisabled,
      );
    }

    if (variant == AppButtonVariant.ghost) {
      return _buildGhostButton(
        content: content,
        height: height,
        horizontalPadding: horizontalPadding,
        textColor: textColor,
        isDisabled: isDisabled,
      );
    }

    // Default filled button (secondary, buy, sell)
    return _buildFilledButton(
      content: content,
      height: height,
      horizontalPadding: horizontalPadding,
      bgColor: bgColor,
      isDisabled: isDisabled,
    );
  }

  Widget _buildGradientButton({
    required Widget content,
    required double height,
    required double horizontalPadding,
    required bool isDisabled,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        height: height,
        width: isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.gradientPrimary,
          ),
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledButton({
    required Widget content,
    required double height,
    required double horizontalPadding,
    required Color bgColor,
    required bool isDisabled,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SizedBox(
        height: height,
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required Widget content,
    required double height,
    required double horizontalPadding,
    required Color borderColor,
    required Color textColor,
    required bool isDisabled,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SizedBox(
        height: height,
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildGhostButton({
    required Widget content,
    required double height,
    required double horizontalPadding,
    required Color textColor,
    required bool isDisabled,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SizedBox(
        height: height,
        width: isFullWidth ? double.infinity : null,
        child: TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  (double, double, double, double) _getSizeStyles() {
    switch (size) {
      case AppButtonSize.small:
        return (36.0, AppTypography.fontSizeSm, 16.0, AppSpacing.md);
      case AppButtonSize.large:
        return (52.0, AppTypography.fontSizeLg, 22.0, AppSpacing.xxl);
      case AppButtonSize.medium:
      default:
        return (44.0, AppTypography.fontSizeMd, 18.0, AppSpacing.xl);
    }
  }

  (Color, Color, Color) _getVariantStyles() {
    switch (variant) {
      case AppButtonVariant.primary:
        return (AppColors.primary, AppColors.textInverse, AppColors.primary);
      case AppButtonVariant.secondary:
        return (AppColors.backgroundElevated, AppColors.textPrimary, AppColors.glassBorder);
      case AppButtonVariant.outline:
        return (Colors.transparent, AppColors.primary, AppColors.primary);
      case AppButtonVariant.ghost:
        return (Colors.transparent, AppColors.primary, Colors.transparent);
      case AppButtonVariant.buy:
        return (AppColors.tradingBuy, AppColors.textInverse, AppColors.tradingBuy);
      case AppButtonVariant.sell:
        return (AppColors.tradingSell, AppColors.textInverse, AppColors.tradingSell);
    }
  }
}

/// Icon-only button variant
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        color: color ?? AppColors.textPrimary,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
