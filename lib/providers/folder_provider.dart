import 'dart:io';
import 'package:flutter/cupertino.dart';

import '../utils/prefrences_util.dart';

class FolderProvider extends ChangeNotifier {
  List<String> _folders = [];
  String? _currentPath;
  List<FileSystemEntity> _items = [];

  List<String> get folders => _folders;
  List<FileSystemEntity> get items => _items;
  String? get currentPath => _currentPath;

  FolderProvider() {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    _folders = await PrefsUtils.getFolders();
    notifyListeners();
  }

  Future<void> addFolder(String path) async {
    if (!_folders.contains(path)) {
      _folders.add(path);
      await PrefsUtils.saveFolders(_folders);
      notifyListeners();
    }
  }

  Future<void> openFolder(String path) async {
    _currentPath = path;
    final dir = Directory(path);
    _items = dir
        .listSync()
        .where((e) =>
    e is Directory || e.path.toLowerCase().endsWith('.mp3'))
        .toList();
    notifyListeners();
  }

  void goUp() {
    if (_currentPath != null) {
      final parent = Directory(_currentPath!).parent.path;
      // If parent is one of your selected folders, go there
      if (_folders.contains(parent)) {
        openFolder(parent);
      } else {
        exitFolder(); // go back to home-level
      }
    }
  }

  Future<void> removeFolder(String path) async {
    _folders.remove(path);
    await PrefsUtils.saveFolders(_folders);
    // If the removed folder is currently open, exit it
    if (_currentPath == path) exitFolder();
    notifyListeners();
  }



  void exitFolder() {
    _currentPath = null;
    _items = [];
    notifyListeners();
  }
}