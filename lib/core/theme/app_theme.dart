import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFFFF6600); // HNオレンジ

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        onPrimary: Colors.white,
        surface: const Color(0xFFFAF9F7),
        onSurface: const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAF9F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0DDD8),
        thickness: 0.5,
        space: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: Color(0xFF1A1A1A),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: Color(0xFF828282),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFFFAF9F7),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        onPrimary: Colors.white,
        surface: const Color(0xFF1A1A1A),
        onSurface: const Color(0xFFE8E6E1),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF242424),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 0.5,
        space: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: Color(0xFFE8E6E1),
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: Color(0xFF828282),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1A1A1A),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
