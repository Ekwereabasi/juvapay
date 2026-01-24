// services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  // 🎯 Change default to .system
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = "user_theme_preference";

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);

    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString = 'system';
    if (mode == ThemeMode.dark) modeString = 'dark';
    if (mode == ThemeMode.light) modeString = 'light';

    await prefs.setString(_themeKey, modeString);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference(mode);
      notifyListeners();
    }
  }
}
