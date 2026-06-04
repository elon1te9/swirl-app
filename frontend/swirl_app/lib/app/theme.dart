import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _primary = Color(0xFF58A6FF);
  static const Color _secondary = Color(0xFFFFD166);
  static const Color _background = Color(0xFFF7FBFF);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF263238);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: _text,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: _text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(color: _text, fontSize: 16, height: 1.4),
      ),
    );
  }
}
