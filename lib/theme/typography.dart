import 'package:flutter/material.dart';
import 'colors.dart';

/// CrymadX Typography System
class AppTypography {
  AppTypography._();

  // Font Sizes
  static const double fontSizeXxs = 10;
  static const double fontSizeXs = 11;
  static const double fontSizeSm = 12;
  static const double fontSizeMd = 14;
  static const double fontSizeLg = 16;
  static const double fontSizeXl = 18;
  static const double fontSizeXxl = 20;
  static const double fontSizeXxxl = 24;
  static const double fontSizeDisplay = 28;
  static const double fontSizeHero = 32;

  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // Text Styles
  static TextStyle get displayLarge => const TextStyle(
        fontSize: fontSizeHero,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: lineHeightTight,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontSize: fontSizeDisplay,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: lineHeightTight,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontSize: fontSizeXxxl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: lineHeightTight,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontSize: fontSizeXxl,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontSize: fontSizeXl,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get titleSmall => const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: lineHeightNormal,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: lineHeightNormal,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: lineHeightNormal,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: lineHeightNormal,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: lineHeightNormal,
      );

  static TextStyle get mono => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: 'monospace',
        height: lineHeightNormal,
      );

  // Accent styles
  static TextStyle get accentLarge => const TextStyle(
        fontSize: fontSizeXl,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: lineHeightTight,
      );

  static TextStyle get accentMedium => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: lineHeightNormal,
      );

  // Trading styles
  static TextStyle get tradingBuy => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppColors.tradingBuy,
        height: lineHeightNormal,
      );

  static TextStyle get tradingSell => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        color: AppColors.tradingSell,
        height: lineHeightNormal,
      );
}
