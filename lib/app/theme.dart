import 'package:flutter/material.dart';

/// True black background for the dark theme (not Material's default dark
/// grey surface) — matches the "dark (black)" look requested.
const _darkBackground = Color(0xFF000000);
const _darkSurface = Color(0xFF121212);

ThemeData buildTakoLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );
}

ThemeData buildTakoDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: Brightness.dark,
  ).copyWith(
    surface: _darkSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _darkSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: _darkSurface,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: _darkBackground),
    navigationRailTheme: const NavigationRailThemeData(backgroundColor: _darkBackground),
    dialogTheme: const DialogThemeData(backgroundColor: _darkSurface),
  );
}
