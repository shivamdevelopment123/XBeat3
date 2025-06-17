

import 'package:flutter/material.dart';

import '../models/audio_file.dart';

class FileTile extends StatelessWidget {
  final AudioFile file;

  const FileTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(file.name),
      onTap: () {
        // Implement audio play logic later
      },
    );
  }
}
