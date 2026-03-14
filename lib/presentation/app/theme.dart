import 'package:flutter/material.dart';

class AuroraTheme {
  AuroraTheme._();

  // Brand colours
  static const _primaryColor = Color(0xFF5B4FCF);   // Aurora purple
  static const _secondaryColor = Color(0xFF1D9E75); // Aurora teal

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          secondary: _secondaryColor,
        ),
        fontFamily: 'Inter', // TODO: add Inter to pubspec fonts
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          secondary: _secondaryColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      );
}
