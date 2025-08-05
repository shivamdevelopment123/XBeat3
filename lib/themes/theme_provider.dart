import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider(this._prefs)
    : _themeMode =
          ThemeMode.values[_prefs?.getInt(_key) ?? ThemeMode.system.index];

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setInt(_key, mode.index);
    notifyListeners();
  }
}
