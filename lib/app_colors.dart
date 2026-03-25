import 'package:flutter/material.dart';

enum AppTheme { light, dark, midnight, forest, purple }

class AppColors {
  static const Color dropRed = Color(0xFFFF1111);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color premiumBlack = Color(0xFF121212);

  // 1. Light Theme (كلاسيكي)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: dropRed, primary: dropRed),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
  );

  // 2. Dark Theme (كلاسيكي)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: dropRed, primary: dropRed, brightness: Brightness.dark),
    scaffoldBackgroundColor: premiumBlack,
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey[800],
  );

  // 3. Midnight Blue Theme (كحلي فاخر)
  static final ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), primary: const Color(0xFF5C6BC0), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0A0E14),
    cardColor: const Color(0xFF151921),
    dividerColor: Colors.white10,
  );

  // 4. Emerald Forest Theme (أخضر زمردي حديث)
  static final ThemeData forestTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C), primary: const Color(0xFF00695C)),
    scaffoldBackgroundColor: const Color(0xFFF4F9F8),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0F2F1),
  );

  // 5. Deep Purple Theme (بنفسجي ملكي)
  static final ThemeData purpleTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A), primary: const Color(0xFFCE93D8), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF120024),
    cardColor: const Color(0xFF1E0036),
    dividerColor: Colors.purple.withOpacity(0.1),
  );

  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light: return lightTheme;
      case AppTheme.dark: return darkTheme;
      case AppTheme.midnight: return midnightTheme;
      case AppTheme.forest: return forestTheme;
      case AppTheme.purple: return purpleTheme;
    }
  }

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getPrimaryTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : Colors.black87;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white70 : Colors.grey[700]!;
  }

  static Color getSubtitleColor(BuildContext context) {
    return getSecondaryTextColor(context);
  }

  static Color getTextColor(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return getPrimaryColor(context);
    return getPrimaryTextColor(context);
  }

  static Color getHintTextColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white38 : Colors.grey[500]!;
  }

  static Color getScaffoldBackground(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color getCardBackground(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return getPrimaryColor(context).withOpacity(0.1);
    return Theme.of(context).cardColor;
  }

  static Color getSecondaryBackground(BuildContext context) {
    return isDarkMode(context) ? Colors.white.withOpacity(0.05) : Colors.grey[100]!;
  }

  static Color getHotDealBackground(BuildContext context) {
    return Colors.orange.withOpacity(isDarkMode(context) ? 0.1 : 0.05);
  }

  static Color getSavingsCardBackground(BuildContext context) {
    return isDarkMode(context) ? Colors.green.withOpacity(0.1) : const Color(0xFFF1F8E9).withOpacity(0.3);
  }

  static List<BoxShadow> getCommonShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(isDarkMode(context) ? 0.3 : 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> getNeumorphicShadow(BuildContext context) {
    final isDark = isDarkMode(context);
    return [
      BoxShadow(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        blurRadius: 15,
        offset: const Offset(-8, -8),
      ),
      BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.12),
        blurRadius: 15,
        offset: const Offset(8, 8),
      ),
    ];
  }

  static BorderSide getCommonBorderSide(BuildContext context) {
    return BorderSide(
      color: isDarkMode(context) ? Colors.white10 : Colors.grey.shade200,
      width: 1,
    );
  }
}

extension AppColorsBorderSideExtension on BorderSide {
  Border toBorder() => Border.all(color: color, width: width);
}
