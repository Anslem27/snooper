import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnooperThemeProvider extends ChangeNotifier {
  bool _darkMode = false;
  bool _amoledDark = false;
  bool _useSystemTheme = true;
  bool _useCustomColor = false;
  Color _customColor = Colors.deepPurple;
  
  bool get darkMode => _darkMode;
  bool get amoledDark => _amoledDark;
  bool get useSystemTheme => _useSystemTheme;
  bool get useCustomColor => _useCustomColor;
  Color get customColor => _customColor;
  
  ThemeMode get themeMode {
    if (_useSystemTheme) return ThemeMode.system;
    return _darkMode ? ThemeMode.dark : ThemeMode.light;
  }
  
  SnooperThemeProvider() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _amoledDark = prefs.getBool('amoled_dark') ?? false;
    _useSystemTheme = prefs.getBool('use_system_theme') ?? true;
    _useCustomColor = prefs.getBool('use_custom_color') ?? false;
    _customColor = Color(prefs.getInt('custom_color') ?? Colors.deepPurple.value);
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    notifyListeners();
  }
  
  Future<void> setAmoledDark(bool value) async {
    _amoledDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('amoled_dark', value);
    notifyListeners();
  }
  
  Future<void> setUseSystemTheme(bool value) async {
    _useSystemTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_system_theme', value);
    notifyListeners();
  }
  
  Future<void> setUseCustomColor(bool value) async {
    _useCustomColor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_custom_color', value);
    notifyListeners();
  }
  
  Future<void> setCustomColor(Color color) async {
    _customColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('custom_color', color.value);
    notifyListeners();
  }
  
  ThemeData getLightTheme() {
    ColorScheme colorScheme;
    
    if (_useCustomColor) {
      colorScheme = ColorScheme.fromSeed(
        seedColor: _customColor,
        brightness: Brightness.light,
      );
    } else {
      // Use default or system dynamic color
      colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      );
    }
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }
  
  ThemeData getDarkTheme() {
    ColorScheme colorScheme;
    
    if (_useCustomColor) {
      colorScheme = ColorScheme.fromSeed(
        seedColor: _customColor,
        brightness: Brightness.dark,
      );
    } else {
      // Use default or system dynamic color
      colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      );
    }
    
    // If AMOLED dark mode is enabled, override background colors
    if (_amoledDark) {
      colorScheme = colorScheme.copyWith(
        surface: Colors.black,
        surfaceContainerHighest: const Color(0xFF121212),
      );
    }
    
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }
}