import 'package:flutter/material.dart';

/// Customized Dark Minimalist Theme for Camera & Media Vault.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0A84FF); // iOS Blue
  static const Color darkBackground = Color(0xFF000000); // True Black for OLED
  static const Color surfaceColor = Color(0xFF1C1C1E); // Apple dark card
  static const Color accentRed = Color(0xFFFF453A); // Recording red indicator
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceColor,
        error: accentRed,
        onPrimary: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
