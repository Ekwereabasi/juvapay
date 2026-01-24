// utils/app_themes.dart

import 'package:flutter/material.dart';

// Define the primary color used throughout the app
const Color _primaryColor = Color(0xFF673AB7);
const MaterialColor _primarySwatch = Colors.deepPurple;

// --- Light Theme Definition ---
ThemeData lightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primarySwatch: _primarySwatch,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white, // Background for cards and containers
    dividerColor: Colors.grey.shade200,

    // AppBar
    appBarTheme: const AppBarTheme(
      color: Colors.white,
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
      backgroundColor: Colors.white,
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
    scaffoldBackgroundColor: const Color(0xFF121212), // Darkest background
    cardColor: const Color(
      0xFF1E1E1E,
    ), // Slightly lighter background for cards/containers
    canvasColor: const Color(0xFF1E1E1E), // Background for Drawers/Menus
    dividerColor: Colors.white12,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212), // Match scaffold for seamless look
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Navigation Bar - THIS FIXES THE TAB BAR DARK MODE
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
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
        foregroundColor: Colors.white, // Better contrast in dark mode
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
