import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../models/audio_file.dart';

class FileProvider extends ChangeNotifier {
  List<AudioFile> _files = [];
  String _currentPath = "/storage/emulated/0"; // Default Android root

  List<AudioFile> get files => _files;
  String get currentPath => _currentPath;

  Future<void> fetchFiles([String? path]) async {
    final dir = Directory(path ?? _currentPath);
    if (!await dir.exists()) return;

    _currentPath = dir.path;
    final List<AudioFile> fetched = [];

    for (var entity in dir.listSync()) {
      final isDir = FileSystemEntity.isDirectorySync(entity.path);
      final name = entity.path.split('/').last;

      if (isDir || entity.path.endsWith('.mp3')) {
        fetched.add(AudioFile(name: name, path: entity.path, isDirectory: isDir));
      }
    }

    _files = fetched;
    notifyListeners();
  }
}