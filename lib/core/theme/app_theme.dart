import 'package:flutter/material.dart';

/// Dark: current app look – purple gradient background, not black.
/// Light: light grey background, dark text.
class AppTheme {
  AppTheme._();

  // Dark (keep existing purple gradient on screens; these are for surfaces/inputs)
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkBackgroundSecondary = Color(0xFF25133A);
  static const Color darkSurface = Color(0xFF1E1B2E);
  static const Color darkOnBackground = Color(0xFFE5E7EB);
  static const Color darkOnSurface = Color(0xFFE5E7EB);
  static const Color darkPrimary = Color(0xFFA78BFA);
  static const Color darkOutline = Color(0x33FFFFFF);
  static const Color darkSecondaryText = Color(0x99FFFFFF);
  static const Color darkChipUnselectedBg = Color(0x1FFFFFFF);

  // Light
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1F2937);
  static const Color lightOnSurface = Color(0xFF374151);
  static const Color lightPrimary = Color(0xFF7C3AED);
  static const Color lightOutline = Color(0xFFD1D5DB);
  static const Color lightSecondaryText = Color(0xFF6B7280);
  static const Color lightChipUnselectedBg = Color(0xFFE5E7EB);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        onPrimary: Colors.white,
        surface: lightSurface,
        onSurface: lightOnSurface,
        surfaceContainerHighest: Color(0xFFE5E7EB),
        error: Color(0xFFDC2626),
        onError: Colors.white,
        outline: lightOutline,
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: lightOnBackground,
        titleTextStyle: TextStyle(
          color: lightOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: lightOutline)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: lightPrimary, width: 2)),
        labelStyle: const TextStyle(color: lightOnSurface),
        hintStyle: const TextStyle(color: lightSecondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: lightOnSurface),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: lightSurface,
          border: const OutlineInputBorder(),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightOnBackground, fontSize: 16),
        bodyMedium: TextStyle(color: lightOnSurface, fontSize: 14),
        titleMedium: TextStyle(color: lightOnBackground, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Colors.white,
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceContainerHighest: Color(0xFF2D2A3E),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: darkOutline,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkOnBackground,
        titleTextStyle: TextStyle(
          color: darkOnBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkOutline)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkPrimary, width: 2)),
        labelStyle: const TextStyle(color: darkOnSurface),
        hintStyle: const TextStyle(color: darkSecondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: darkOnSurface),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: darkSurface,
          border: const OutlineInputBorder(),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkOnBackground, fontSize: 16),
        bodyMedium: TextStyle(color: darkOnSurface, fontSize: 14),
        titleMedium: TextStyle(color: darkOnBackground, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
