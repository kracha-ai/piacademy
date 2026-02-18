import 'package:flutter/material.dart';
class ThemeNotifier with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light; // Default to light theme
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Important: tell widgets listening that the theme has changed
  }
}