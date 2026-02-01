// utils/app_themes.dart

import 'package:flutter/material.dart';

// Define the primary color used throughout the app
const Color _primaryColor = Color(0xFF673AB7);
const MaterialColor _primarySwatch = Colors.deepPurple;

// Light Theme Colors
const Color _lightHintColor = Color(0xFF757575);
const Color _lightDisabledColor = Color(0xFFC2C2C2);
const Color _lightSurface = Colors.white;
const Color _lightBackground = Colors.white;
const Color _lightOnSurface = Colors.black87;

// Dark Theme Colors
const Color _darkHintColor = Color(0xFFAAAAAA);
const Color _darkDisabledColor = Color(0xFF555555);
const Color _darkSurface = Color(0xFF1E1E1E);
const Color _darkBackground = Color(0xFF121212);
const Color _darkOnSurface = Colors.white70;

// --- Light Theme Definition ---
ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: _primarySwatch,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightSurface,
    dividerColor: Colors.grey.shade200,
    hintColor: _lightHintColor,
    disabledColor: _lightDisabledColor,
    // ColorScheme for Flutter's Material Design 3 support
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      surface: _lightSurface,
      onSurface: _lightOnSurface,
      background: _lightBackground,
      onBackground: _lightOnSurface,
      secondary: Colors.purple.shade300,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      outline: Colors.grey.shade400,
    ),

    // AppBar - FIXED: Removed redundant const keywords
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightSurface,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      actionsIconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightSurface,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
    ),

    // Text Theme
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.grey),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: _primaryColor, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// --- Dark Theme Definition ---
ThemeData darkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: _primarySwatch,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkSurface,
    canvasColor: _darkSurface,
    dividerColor: Colors.white12,
    hintColor: _darkHintColor,
    disabledColor: _darkDisabledColor,
    // ColorScheme for Flutter's Material Design 3 support
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      onPrimary: Colors.white,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
      background: _darkBackground,
      onBackground: _darkOnSurface,
      secondary: Colors.purple.shade300,
      onSecondary: Colors.white,
      error: Colors.red.shade400,
      onError: Colors.white,
      outline: Colors.white24,
    ),

    // AppBar - FIXED: Removed redundant const keywords
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.white54,
    ),

    // Text Theme
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white54),
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: _primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
