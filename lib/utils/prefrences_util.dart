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
}