import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../utils/prefrences_util.dart';

class FolderProvider extends ChangeNotifier {
  List<String> _folders = [];
  String? _currentPath;
  List<FileSystemEntity> _items = [];
  bool _autoFetchEnabled = false;

  List<String> get folders => _folders;
  List<FileSystemEntity> get items => _items;
  String? get currentPath => _currentPath;
  bool get autoFetchEnabled => _autoFetchEnabled;

  FolderProvider() {
    _init();
  }

  Future<void> _init() async {
    _folders = await PrefsUtils.getFolders();
    _autoFetchEnabled = await PrefsUtils.getAutoFetchAudioEnabled();
    notifyListeners();
  }

  Future<void> addFolder(String path) async {
    if (!_folders.contains(path)) {
      _folders.add(path);
      await PrefsUtils.saveFolders(_folders);
      notifyListeners();
    }
  }

  Future<void> autoFetchAudioFolders() async {
    final rootDir = Directory('/storage/emulated/0');
    if (!await rootDir.exists()) {
      print("Root directory not accessible");
      return;
    }

    final Set<String> foundFolders = {};

    final restrictedDirs = [
      "/storage/emulated/0/Android",
      "/storage/emulated/0/LOST.DIR",
      "/storage/emulated/0/.Trash-",
      "/storage/emulated/0/.thumbnails",
      "/storage/emulated/0/.hidden",
      "/storage/emulated/0/.temp"
    ];

    Future<void> scanDir(Directory dir) async {
      final path = dir.path;

      if (restrictedDirs.any((b) => path.startsWith(b)) ||
          path.split('/').any((segment) => segment.startsWith('.'))) {
        return;
      }

      try {
        await for (var entity in dir.list(followLinks: false)) {
          if (entity is File) {
            final lower = entity.path.toLowerCase();
            if (lower.endsWith('.mp3') || lower.endsWith('.wav')) {
              foundFolders.add(File(entity.path).parent.path);
            }
          } else if (entity is Directory) {
            await scanDir(entity); // recurse manually
          }
        }
      } catch (e) {
        print("Skipping directory due to error: $e");
      }
    }

    await scanDir(rootDir);

    print("Found ${foundFolders.length} folders with audio files");

    final merged = {..._folders, ...foundFolders}.toList();
    _folders = merged;

    await PrefsUtils.saveFolders(_folders);
    notifyListeners();
  }

  Future<void> setAutoFetchEnabled(bool enabled) async {
    _autoFetchEnabled = enabled;
    notifyListeners();
    await PrefsUtils.setAutoFetchAudioEnabled(enabled);
    if (enabled) {
      await autoFetchAudioFolders();
    }
    notifyListeners();
  }

  Future<void> openFolder(String path) async {
    _currentPath = path;
    final dir = Directory(path);
    _items = dir
        .listSync()
        .where((e) =>
    e is Directory || e.path.toLowerCase().endsWith('.mp3') || e.path.toLowerCase().endsWith('.wav'))
        .toList();
    notifyListeners();
  }

  void refreshCurrentFolder() {
    if (currentPath != null) {
      openFolder(currentPath!);
    }
  }

  void goUp() {
    if (_currentPath != null) {
      final parent = Directory(_currentPath!).parent.path;
      if (_folders.contains(parent)) {
        openFolder(parent);
      } else {
        exitFolder();
      }
    }
  }

  Future<void> removeFolder(String path) async {
    _folders.remove(path);
    await PrefsUtils.saveFolders(_folders);
    if (_currentPath == path) exitFolder();
    notifyListeners();
  }

  void exitFolder() {
    _currentPath = null;
    _items = [];
    notifyListeners();
  }
}
