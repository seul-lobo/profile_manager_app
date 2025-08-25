import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeKey) ?? 0;

      if (themeModeIndex == 1) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading theme mode: $e');
      _themeMode = ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final index = themeMode == ThemeMode.dark ? 1 : 0;
      await prefs.setInt(_themeKey, index);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  bool get isLightMode {
    return _themeMode == ThemeMode.light;
  }

  //simple toggle between light and dark only
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  String get themeModeName {
    return _themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  }

  IconData get themeIcon {
    return _themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode;
  }
}
