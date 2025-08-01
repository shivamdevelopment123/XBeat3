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

}