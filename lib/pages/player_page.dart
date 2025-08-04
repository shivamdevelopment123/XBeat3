import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/components/neu_box.dart';
import 'package:xbeat3/widgets/main_play_controls.dart';
import 'package:xbeat3/widgets/middle_modification_controls.dart';
import 'package:xbeat3/widgets/seekbar_time.dart';
import 'package:xbeat3/widgets/songs_queue_list.dart';
import 'package:xbeat3/widgets/title_artist_playerpage.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/song_info_sheet.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player = audioProv.player;
    final seq = player.sequence;

    if (seq == null || seq.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('N O W     P L A Y I N G'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentIndex = audioProv.currentIndex.clamp(0, seq.length - 1);
    final mediaItem = seq[currentIndex].tag as MediaItem;
    final songPath = mediaItem.id;

    Widget buildArtWithInfo() {
      final item = seq[currentIndex].tag as MediaItem;
      final uri = item.artUri;
      final songPath = item.id;

      Widget imageWidget;
      if (uri != null && uri.scheme == 'file') {
        imageWidget = Image.file(File(uri.toFilePath()), fit: BoxFit.cover);
      } else if (uri != null && uri.scheme == 'asset') {
        imageWidget = Image.asset(
          uri.path.replaceFirst('/', ''),
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = const Icon(Icons.music_note, size: 100);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(width: double.infinity, height: 240, child: imageWidget),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black38,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.info, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      backgroundColor: Theme.of(context).colorScheme.background,
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SongInfoSheet(
                        songPath: songPath,
                        title: item.title,
                        album: item.album ?? '',
                        artist: item.artist ?? '',
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('N O W      P L A Y I N G'),
        centerTitle: true,
        actions: [],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    if (audioProv.hasNext) {
                      audioProv.skipToNext();
                    }
                  } else if (details.primaryVelocity! > 0) {
                    if (audioProv.hasPrevious) {
                      audioProv.skipToPrevious();
                    }
                  }
                },
                child: NeuBox(
                  child: Column(
                    children: [
                      buildArtWithInfo(),

                      const SizedBox(height: 10),

                      TitleArtistPlayerpage(songPath: songPath),

                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            MiddleModificationControls(),

            const SizedBox(height: 0),

            SeekbarTime(),

            const SizedBox(height: 15),

            MainPlayControls(),

            const SizedBox(height: 7),

            SongsQueueList(),
          ],
        ),
      ),
    );
  }
}
