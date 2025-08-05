import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/components/marque_scrolling_text.dart';
import 'package:xbeat3/components/my_drawer.dart';
import 'package:xbeat3/pages/player_page.dart';
import '../components/mini_player_bar.dart';
import '../providers/audio_player_provider.dart';
import '../providers/folder_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final folderProv = context.watch<FolderProvider>();
    final audioProv  = context.read<AudioPlayerProvider>();

    final raw = folderProv.currentPath ?? '';
    final display = raw.replaceFirst('/storage/emulated/0/', '');

    void confirmRemove(BuildContext context, String path) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Remove folder?'),
          content: Text('Delete "${path.split('/').last}" from your list?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600),)),
            TextButton(
              onPressed: () {
                context.read<FolderProvider>().removeFolder(path);
                Navigator.pop(context);
              },
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (folderProv.currentPath != null) {
          folderProv.goUp();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
          title: Text(display.isEmpty ? 'Home' : display),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final path = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: 'Select a folder',
                  initialDirectory: Platform.isAndroid
                      ? '/storage/emulated/0'
                      : '/',
                );
                if (path != null) folderProv.addFolder(path);
              },
            )
          ],
        ),
        body: SafeArea(
          child: folderProv.currentPath == null
              ? ListView(
            children: folderProv.folders
                .map((path) => GestureDetector(
              onLongPress: () => confirmRemove(context, path),
                  child: ListTile(
                              leading: const Icon(Icons.folder_shared),
                              title: Text(path.split('/').last),
                              onTap: () => folderProv.openFolder(path),
                            ),
                )).toList(),
          )
              : _buildFileList(context, folderProv, audioProv),
        ),
        drawer: MyDrawer(),
        bottomNavigationBar: SafeArea(child: const MiniPlayerBar()),
      ),
    );
  }

  Widget _buildFileList(BuildContext context,
      FolderProvider folderProv, AudioPlayerProvider audioProv) {
    final allEntities = folderProv.items;
    final audioFiles = allEntities
        .where((e) =>
    e is File &&
        (e.path.endsWith('.mp3') || e.path.endsWith('.wav')))
        .cast<File>()
        .toList();

    void showFileOptions(File file, int index) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor:
                          Theme.of(context).colorScheme.surface,
                          title: const Text('Delete file?'),
                          content: Text(
                              'Are you sure you want to delete "${file.path.split('/').last}" from storage?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: Colors.grey.shade600)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child:
                              const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await file.delete();
                          folderProv.refreshCurrentFolder();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File deleted')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
                          );
                        }
                      }
                    },
                  ),
                  if (audioProv.isPlaying) ...[
                    ListTile(
                      leading: const Icon(Icons.queue_play_next),
                      title: const Text('Play Next'),
                      onTap: () async {
                        Navigator.pop(context);
                        final metadata =
                        await MetadataRetriever.fromFile(file);
                        final mediaItem = MediaItem(
                          id: file.path,
                          album: metadata.albumName ?? 'Unknown Album',
                          title: metadata.trackName ?? file.path.split('/').last,
                          artist: metadata.trackArtistNames?.join(', ') ??
                              'Unknown Artist',
                        );
                        await audioProv.playNext(file.path, mediaItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to play next')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: const Text('Add to Queue'),
                      onTap: () async {
                        Navigator.pop(context);
                        final metadata =
                        await MetadataRetriever.fromFile(file);
                        final mediaItem = MediaItem(
                          id: file.path,
                          album: metadata.albumName ?? 'Unknown Album',
                          title: metadata.trackName ?? file.path.split('/').last,
                          artist: metadata.trackArtistNames?.join(', ') ??
                              'Unknown Artist',
                        );
                        final playlist = audioProv.player.audioSource
                        as ConcatenatingAudioSource;
                        await playlist.add(AudioSource.uri(Uri.file(file.path),
                            tag: mediaItem));
                        audioProv.addToPlaylist(file.path);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to queue')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      itemCount: audioFiles.length,
      itemBuilder: (_, index) {
        final file = audioFiles[index];
        final name = file.path.split('/').last;
        return ListTile(
          leading: const Icon(Icons.music_note),
          title: SizedBox(
            height: 20,
            child: MarqueeText(text: name),
          ),
          onTap: () async {
            final uris = audioFiles.map((f) => f.path).toList();
            audioProv.setPlaylist(uris, startIndex: index);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerPage()),
            );
          },
          onLongPress: () => showFileOptions(file, index),
        );
      },
    );
  }

}