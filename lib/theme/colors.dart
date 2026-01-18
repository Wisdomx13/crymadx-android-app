import 'package:flutter/material.dart';

/// CrymadX Mobile Theme - Supports both Dark and Light themes
/// Dark: Pure black with Bybit green accents
/// Light: Clean white with green accents

class AppColors {
  AppColors._();

  // Primary - Vibrant Authentic Green (same for both themes)
  static const Color primary50 = Color(0xFFE8FFF4);
  static const Color primary100 = Color(0xFFC6FFE5);
  static const Color primary200 = Color(0xFF8CFFC9);
  static const Color primary300 = Color(0xFF4DFF9E);
  static const Color primary400 = Color(0xFF00E676); // Vibrant authentic green
  static const Color primary500 = Color(0xFF00C853); // Rich green
  static const Color primary600 = Color(0xFF00A844);
  static const Color primary700 = Color(0xFF008836);
  static const Color primary800 = Color(0xFF006828);
  static const Color primary900 = Color(0xFF00481A);
  static const Color primary = primary400;

  // Secondary - Teal
  static const Color secondary50 = Color(0xFFE3F5F3);
  static const Color secondary100 = Color(0xFFB8E6E1);
  static const Color secondary200 = Color(0xFF8AD5CD);
  static const Color secondary300 = Color(0xFF5CC4B9);
  static const Color secondary400 = Color(0xFF00A896);
  static const Color secondary500 = Color(0xFF009485);
  static const Color secondary600 = Color(0xFF008074);
  static const Color secondary700 = Color(0xFF006C63);
  static const Color secondary800 = Color(0xFF005852);
  static const Color secondary900 = Color(0xFF004441);
  static const Color secondary = secondary400;

  // ============ DARK THEME COLORS ============

  // Background - Ultra Pure Black with Glassy Tint
  static const Color backgroundPrimary = Color(0xFF000000);
  static const Color backgroundSecondary = Color(0xFF010101);
  static const Color backgroundElevated = Color(0xFF020202);
  static const Color backgroundCard = Color(0xFF010101);
  static const Color backgroundHover = Color(0xFF030303);
  static const Color backgroundInput = Color(0xFF020202);
  static const Color backgroundSurface = Color(0xFF030303);
  static const Color backgroundContainer = Color(0xFF000000);
  static const Color backgroundDeep = Color(0xFF000000);
  static const Color backgroundGlassy = Color(0xFF010101);

  // Text Colors - Dark Theme
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // 60% opacity
  static const Color textTertiary = Color(0x73FFFFFF); // 45% opacity
  static const Color textMuted = Color(0x59FFFFFF); // 35% opacity
  static const Color textInverse = Color(0xFF000000);
  static const Color textAccent = primary400;

  // Glass Effects - Premium Glossy Black
  static const Color glassBorder = Color(0x08FFFFFF);
  static const Color glassBorderLight = Color(0x0CFFFFFF);
  static const Color glassBorderAccent = Color(0x180ECB81);
  static const Color glassFrosted = Color(0xFF000000);
  static const Color glassOverlay = Color(0xFF000000);
  static const Color glassSubtle = Color(0x03FFFFFF);
  static const Color glassShine = Color(0x06FFFFFF);
  static const Color glassGlow = Color(0x0A0ECB81);
  static const Color glassCard = Color(0xFF010101);
  static const Color glassReflection = Color(0x08FFFFFF);
  static const Color glossyBlack = Color(0xFF000000);

  // ============ LIGHT THEME COLORS ============

  // Background - Clean Light Theme
  static const Color lightBackgroundPrimary = Color(0xFFFFFFFF);
  static const Color lightBackgroundSecondary = Color(0xFFF8F9FA);
  static const Color lightBackgroundElevated = Color(0xFFFFFFFF);
  static const Color lightBackgroundCard = Color(0xFFFFFFFF);
  static const Color lightBackgroundHover = Color(0xFFF5F5F5);
  static const Color lightBackgroundInput = Color(0xFFF5F6F8);
  static const Color lightBackgroundSurface = Color(0xFFFAFAFA);
  static const Color lightBackgroundContainer = Color(0xFFFFFFFF);
  static const Color lightBackgroundDeep = Color(0xFFF0F2F5);
  static const Color lightBackgroundGlassy = Color(0xFFFAFBFC);

  // Text Colors - Light Theme (Very black for maximum visibility)
  static const Color lightTextPrimary = Color(0xFF000000);  // Pure black
  static const Color lightTextSecondary = Color(0xFF111111);  // Very dark
  static const Color lightTextTertiary = Color(0xFF222222);  // Dark
  static const Color lightTextMuted = Color(0xFF333333);  // Medium dark (still very readable)
  static const Color lightTextInverse = Color(0xFFFFFFFF);

  // Glass Effects - Light Theme
  static const Color lightGlassBorder = Color(0x12000000);
  static const Color lightGlassBorderLight = Color(0x08000000);
  static const Color lightGlassBorderAccent = Color(0x200ECB81);
  static const Color lightGlassFrosted = Color(0xFFFFFFFF);
  static const Color lightGlassOverlay = Color(0xFFF8F9FA);
  static const Color lightGlassSubtle = Color(0x05000000);
  static const Color lightGlassShine = Color(0x08000000);
  static const Color lightGlassGlow = Color(0x150ECB81);
  static const Color lightGlassCard = Color(0xFFFFFFFF);
  static const Color lightGlassReflection = Color(0x08000000);

  // ============ COMMON COLORS (Both themes) ============

  // Trading Colors - Vibrant Authentic
  static const Color tradingBuy = Color(0xFF00E676); // Vibrant green
  static const Color tradingSell = Color(0xFFFF1744); // Vibrant red
  static const Color tradingBuyBg = Color(0x2000E676); // 12% opacity
  static const Color tradingSellBg = Color(0x20FF1744); // 12% opacity

  // Status Colors - Vibrant
  static const Color success = Color(0xFF00E676); // Vibrant green
  static const Color error = Color(0xFFFF1744); // Vibrant red
  static const Color warning = Color(0xFFF0B90B);
  static const Color info = Color(0xFF1E88E5);
  static const Color successBg = Color(0x1A0ECB81);
  static const Color errorBg = Color(0x1AF6465D);
  static const Color warningBg = Color(0x1AF0B90B);
  static const Color infoBg = Color(0x1A1E88E5);

  // Status aliases for compatibility
  static const Color statusWarning = warning;
  static const Color statusWarningBg = warningBg;
  static const Color statusSuccess = success;
  static const Color statusSuccessBg = successBg;
  static const Color statusError = error;
  static const Color statusErrorBg = errorBg;

  // Crypto Brand Colors
  static const Color cryptoBtc = Color(0xFFF7931A);
  static const Color cryptoEth = Color(0xFF627EEA);
  static const Color cryptoUsdt = Color(0xFF26A17B);
  static const Color cryptoBnb = Color(0xFFF3BA2F);
  static const Color cryptoSol = Color(0xFF00D18C);
  static const Color cryptoXrp = Color(0xFF23292F);
  static const Color cryptoAda = Color(0xFF0033AD);
  static const Color cryptoAvax = Color(0xFFE84142);
  static const Color cryptoDot = Color(0xFFE6007A);
  static const Color cryptoMatic = Color(0xFF8247E5);
  static const Color cryptoTrx = Color(0xFFFF0013);

  // Gradients
  static const List<Color> gradientPrimary = [primary400, primary700];
  static const List<Color> gradientPrimarySubtle = [Color(0x0D0ECB81), Color(0x030ECB81)];
  static const List<Color> gradientDark = [Color(0xFF020202), Color(0xFF000000)];
  static const List<Color> gradientLight = [Color(0xFFFFFFFF), Color(0xFFF5F5F5)];
  static const List<Color> gradientGlass = [Color(0x03FFFFFF), Color(0x01FFFFFF)];
  static const List<Color> gradientCardShine = [Color(0x05FFFFFF), Color(0x00FFFFFF)];
}

/// Get crypto color by symbol
Color getCryptoColor(String symbol) {
  switch (symbol.toUpperCase()) {
    case 'BTC':
      return AppColors.cryptoBtc;
    case 'ETH':
      return AppColors.cryptoEth;
    case 'USDT':
    case 'USDC':
      return AppColors.cryptoUsdt;
    case 'BNB':
      return AppColors.cryptoBnb;
    case 'SOL':
      return AppColors.cryptoSol;
    case 'XRP':
      return AppColors.cryptoXrp;
    case 'ADA':
      return AppColors.cryptoAda;
    case 'AVAX':
      return AppColors.cryptoAvax;
    case 'DOT':
      return AppColors.cryptoDot;
    case 'MATIC':
      return AppColors.cryptoMatic;
    case 'TRX':
      return AppColors.cryptoTrx;
    default:
      return AppColors.primary400;
  }
}

/// Extension to get theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Background colors
  Color get backgroundColor => isDarkMode ? AppColors.backgroundPrimary : AppColors.lightBackgroundPrimary;
  Color get backgroundSecondaryColor => isDarkMode ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary;
  Color get backgroundCardColor => isDarkMode ? AppColors.backgroundCard : AppColors.lightBackgroundCard;
  Color get backgroundInputColor => isDarkMode ? AppColors.backgroundInput : AppColors.lightBackgroundInput;
  Color get backgroundElevatedColor => isDarkMode ? AppColors.backgroundElevated : AppColors.lightBackgroundElevated;
  Color get backgroundSurfaceColor => isDarkMode ? AppColors.backgroundSurface : AppColors.lightBackgroundSurface;

  // Text colors
  Color get textPrimaryColor => isDarkMode ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textTertiaryColor => isDarkMode ? AppColors.textTertiary : AppColors.lightTextTertiary;
  Color get textMutedColor => isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;
  Color get textInverseColor => isDarkMode ? AppColors.textInverse : AppColors.lightTextInverse;

  // Glass effects
  Color get glassBorderColor => isDarkMode ? AppColors.glassBorder : AppColors.lightGlassBorder;
  Color get glassCardColor => isDarkMode ? AppColors.glassCard : AppColors.lightGlassCard;
}
