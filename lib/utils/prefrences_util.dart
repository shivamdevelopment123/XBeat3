import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsUtils {
  static const _keyFolders = 'selected_folders';

  static Future<List<String>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFolders) ?? [];
  }

  static Future<void> saveFolders(List<String> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFolders, folders);
  }

  static Future<void> saveLastPlayedSong(String songPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_played_song', songPath);
  }

  static Future<String?> getLastPlayedSong() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_played_song');
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    return ThemeMode.values[index];
  }

  static Future<void> saveEqualizerMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('equalizer_mode', mode);
  }

  static Future<int> getEqualizerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('equalizer_mode') ?? 0;
  }

}