import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

enum AppTheme { light, dark, midnight, forest, purple, pink }

class AppColors {
  static const Color dropRed = Color(0xFFFF1111);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color premiumBlack = Color(0xFF121212);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: dropRed, primary: dropRed),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: dropRed, primary: dropRed, brightness: Brightness.dark),
    scaffoldBackgroundColor: premiumBlack,
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.grey[800],
  );

  static final ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), primary: const Color(0xFF5C6BC0), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0A0E14),
    cardColor: const Color(0xFF151921),
    dividerColor: Colors.white10,
  );

  static final ThemeData forestTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C), primary: const Color(0xFF00695C)),
    scaffoldBackgroundColor: const Color(0xFFF4F9F8),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0F2F1),
  );

  static final ThemeData purpleTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A), primary: const Color(0xFFCE93D8), brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF120024),
    cardColor: const Color(0xFF1E0036),
    dividerColor: Colors.purple.withOpacity(0.1),
  );

  static final ThemeData pinkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63), primary: const Color(0xFFF06292)),
    scaffoldBackgroundColor: const Color(0xFFFFF1F6),
    cardColor: Colors.white,
    dividerColor: Colors.pink.withOpacity(0.1),
  );

  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light: return lightTheme;
      case AppTheme.dark: return darkTheme;
      case AppTheme.midnight: return midnightTheme;
      case AppTheme.forest: return forestTheme;
      case AppTheme.purple: return purpleTheme;
      case AppTheme.pink: return pinkTheme;
    }
  }

  static Color getPrimaryColor(BuildContext context) => Theme.of(context).colorScheme.primary;
  static bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color getPrimaryTextColor(BuildContext context) => isDarkMode(context) ? Colors.white : Colors.black87;
  static Color getSecondaryTextColor(BuildContext context) => isDarkMode(context) ? Colors.white70 : Colors.grey[700]!;
  static Color getSubtitleColor(BuildContext context) => getSecondaryTextColor(context);
  static Color getScaffoldBackground(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color getSecondaryBackground(BuildContext context) => isDarkMode(context) ? Colors.white.withOpacity(0.05) : Colors.grey[100]!;
  static Color getCardBackground(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return getPrimaryColor(context).withOpacity(0.1);
    return Theme.of(context).cardColor;
  }
  static Color getHintTextColor(BuildContext context) => isDarkMode(context) ? Colors.white38 : Colors.grey[500]!;
  static Color getHotDealBackground(BuildContext context) => Colors.orange.withOpacity(isDarkMode(context) ? 0.1 : 0.05);
  static Color getSavingsCardBackground(BuildContext context) => isDarkMode(context) ? Colors.green.withOpacity(0.1) : const Color(0xFFF1F8E9).withOpacity(0.3);
  
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
      BoxShadow(color: isDark ? Colors.white.withOpacity(0.02) : Colors.white, blurRadius: 15, offset: const Offset(-8, -8)),
      BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(8, 8)),
    ];
  }
  
  static BorderSide getCommonBorderSide(BuildContext context) => BorderSide(color: isDarkMode(context) ? Colors.white10 : Colors.grey.shade200, width: 1);

  static void showThemedDialog({
    required BuildContext context,
    required String title,
    required String description,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    String? secondaryButtonText,
    Color? primaryButtonColor,
    IconData? icon,
  }) {
    final isDark = isDarkMode(context);
    final primaryColor = primaryButtonColor ?? getPrimaryColor(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222222) : Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: primaryColor, size: 40),
                const SizedBox(height: 15),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      (secondaryButtonText ?? "cancel_button").tr(), 
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onPrimaryPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(primaryButtonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color getTextColor(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return getPrimaryColor(context);
    return getPrimaryTextColor(context);
  }
}

extension AppColorsBorderSideExtension on BorderSide {
  Border toBorder() => Border.all(color: color, width: width);
}
