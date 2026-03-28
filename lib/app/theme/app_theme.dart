import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color red = Color(0xFFE53935);
  static const Color black = Color(0xFF121212);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF5F5F5);
  static const Color lightGray = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: red,
      brightness: Brightness.light,
    ).copyWith(
      primary: red,
      onPrimary: white,
      secondary: black,
      onSecondary: white,
      surface: white,
      onSurface: black,
      onSurfaceVariant: const Color(0xFF4F4F4F),
      outline: const Color(0xFFBDBDBD),
      outlineVariant: lightGray,
      shadow: const Color(0x33000000),
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
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightGray),
        ),
      ),
      dividerTheme: const DividerThemeData(color: lightGray, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        hintStyle: const TextStyle(color: Color(0xFF616161)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: Color(0xFFBDBDBD)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
        labelStyle: const TextStyle(color: black, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          color: white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lightGray),
        ),
      ),
      textTheme: Typography.blackMountainView.copyWith(
        headlineSmall: const TextStyle(
          color: black,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          color: black,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
        ),
        titleMedium: const TextStyle(
          color: black,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.15,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
