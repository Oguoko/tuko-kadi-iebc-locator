import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color red = Color(0xFFD7261E);
  static const Color black = Color(0xFF0A0A0A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF3F1ED);
  static const Color lightGray = Color(0xFFDDD7CF);

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: red,
      brightness: Brightness.light,
    ).copyWith(
      primary: red,
      onPrimary: white,
      secondary: black,
      onSecondary: white,
      primaryContainer: const Color(0xFFFFE3E0),
      onPrimaryContainer: const Color(0xFF450A06),
      surface: white,
      onSurface: black,
      onSurfaceVariant: const Color(0xFF3F3B37),
      outline: const Color(0xFF9A948D),
      outlineVariant: lightGray,
      shadow: const Color(0x3A000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: offWhite,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: offWhite,
        foregroundColor: black,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lightGray),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightGray, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        hintStyle: const TextStyle(
          color: Color(0xFF5D5954),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: Color(0xFF9A948D)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: black,
        foregroundColor: white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: white,
        selectedColor: red,
        secondarySelectedColor: red,
        disabledColor: lightGray,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(
          color: black,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        secondaryLabelStyle: const TextStyle(
          color: white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: lightGray),
        ),
      ),
      textTheme: Typography.blackMountainView.copyWith(
        headlineSmall: const TextStyle(
          color: black,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.55,
        ),
        titleLarge: const TextStyle(
          color: black,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
        ),
        titleMedium: const TextStyle(
          color: black,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.18,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
