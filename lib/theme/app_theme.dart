import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

// Export all theme-related files
export 'colors.dart';
export 'typography.dart';
export 'spacing.dart';

/// CrymadX App Theme - Supports Dark and Light modes
class AppTheme {
  AppTheme._();

  // ============ DARK THEME ============
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.backgroundCard,
        error: AppColors.error,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: AppTypography.fontSizeXl,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppTypography.fontSizeMd,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppTypography.fontSizeSm,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTypography.fontSizeMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundCard,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTypography.fontSizeSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.backgroundCard,
      ),

      // Tab Bar
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============ LIGHT THEME ============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.lightBackgroundCard,
        error: AppColors.error,
        onPrimary: AppColors.lightTextInverse,
        onSecondary: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onError: AppColors.lightTextInverse,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackgroundPrimary,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackgroundPrimary,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: AppTypography.fontSizeXl,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightTextPrimary,
          size: 24,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBackgroundPrimary,
        selectedItemColor: AppColors.lightTextPrimary,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.lightBackgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(
            color: AppColors.lightGlassBorder,
            width: 1,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBackgroundInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.lightGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextMuted,
          fontSize: AppTypography.fontSizeMd,
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: AppTypography.fontSizeSm,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightTextInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(
            fontSize: AppTypography.fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightGlassBorder,
        thickness: 1,
        space: 1,
      ),

      // Text Theme - Light mode text styles
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppTypography.fontSizeHero,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightTight,
        ),
        displayMedium: TextStyle(
          fontSize: AppTypography.fontSizeDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightTight,
        ),
        headlineLarge: TextStyle(
          fontSize: AppTypography.fontSizeXxxl,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightTight,
        ),
        headlineMedium: TextStyle(
          fontSize: AppTypography.fontSizeXxl,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        headlineSmall: TextStyle(
          fontSize: AppTypography.fontSizeXl,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        titleLarge: TextStyle(
          fontSize: AppTypography.fontSizeLg,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        titleMedium: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        titleSmall: TextStyle(
          fontSize: AppTypography.fontSizeSm,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        bodyLarge: TextStyle(
          fontSize: AppTypography.fontSizeLg,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        bodyMedium: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        bodySmall: TextStyle(
          fontSize: AppTypography.fontSizeSm,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextSecondary,
          height: AppTypography.lineHeightNormal,
        ),
        labelLarge: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextPrimary,
          height: AppTypography.lineHeightNormal,
        ),
        labelMedium: TextStyle(
          fontSize: AppTypography.fontSizeSm,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextSecondary,
          height: AppTypography.lineHeightNormal,
        ),
        labelSmall: TextStyle(
          fontSize: AppTypography.fontSizeXs,
          fontWeight: FontWeight.w500,
          color: AppColors.lightTextTertiary,
          height: AppTypography.lineHeightNormal,
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
        size: 24,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightBackgroundElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppTypography.fontSizeMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightBackgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.lightBackgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: const TextStyle(
          fontSize: AppTypography.fontSizeXl,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBackgroundCard,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: AppTypography.fontSizeSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.lightGlassBorder),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightBackgroundCard,
      ),

      // Tab Bar
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.lightTextPrimary,
        unselectedLabelColor: AppColors.lightTextMuted,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppTypography.fontSizeMd,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
