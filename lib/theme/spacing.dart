import 'package:flutter/material.dart';

/// CrymadX Spacing & Border Radius Constants

class AppSpacing {
  AppSpacing._();

  // Spacing Scale
  static const double xxs = 2;
  static const double xs = 3;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 22;
  static const double xxxl = 28;

  // Common paddings
  static const double screenPadding = md;
  static const double cardPadding = md;
  static const double sectionGap = lg;
  static const double itemGap = sm;

  // Radius aliases for convenience (use AppRadius for full set)
  static const double radiusXs = AppRadius.xs;
  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusXl = AppRadius.xl;
}

class AppRadius {
  AppRadius._();

  // Border Radius
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 9999;

  // Common use cases
  static const double button = md;
  static const double card = lg;
  static const double input = md;
  static const double modal = xl;
  static const double avatar = full;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: const Color(0x0D000000),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: const Color(0x1A000000),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: const Color(0x1A0ECB81),
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ];
}
