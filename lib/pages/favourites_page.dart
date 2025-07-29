import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:xbeat3/pages/player_page.dart';
import '../components/file_tile.dart';
import '../models/audio_file.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favourite_provider.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavouriteProvider>();
    final audioProv  = context.read<AudioPlayerProvider>();
    final favPaths = favProv.allFavs;

    final favFiles = favPaths.map((path) {
      final name = p.basename(path);
      return AudioFile(
        name: name,
        path: path,
        isDirectory: Directory(path).statSync().type == FileSystemEntityType.directory,
      );
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: const Text('F A V O U R I T E S'),
        centerTitle: true,
      ),
      body: favFiles.isEmpty
          ? const Center(
        child: Text(
          'No favourites added yet.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: favFiles.length,
        itemBuilder: (context, index) {
          final file = favFiles[index];
          return ListTile(
            leading: const Icon(Icons.favorite),
            title: Text(file.name),
            onTap: () async {
              final uris = favFiles.map((f) => f.path).toList();
              audioProv.setPlaylist(uris, startIndex: index);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerPage()),
              );
            },
          );
        },
      ),
    );
  }
}
