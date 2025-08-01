import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xbeat3/components/neu_box.dart';
import 'package:xbeat3/widgets/main_play_controls.dart';
import 'package:xbeat3/widgets/songs_queue_list.dart';
import '../components/equalizer_bottom_sheet.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favourite_provider.dart';
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
    final favProv = context.watch<FavouriteProvider>();
    final isFav = favProv.isFav(songPath);

    /*Widget _buildArt() {
      final item = seq[currentIndex].tag as MediaItem;
      final uri = item.artUri;

      if (uri != null && uri.scheme == 'file') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(uri.toFilePath()),
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.music_note, size: 100),
          ),
        );
      } else if (uri != null && uri.scheme == 'asset') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            uri.path.replaceFirst('/', ''),
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.music_note, size: 100),
          ),
        );
      }

      return const SizedBox(
        width: double.infinity,
        height: 240,
        child: Icon(Icons.music_note, size: 100),
      );
    }*/

    Widget _buildArtWithInfo() {
      final item = seq[currentIndex].tag as MediaItem;
      final uri = item.artUri;
      final songPath = item.id;

      Widget imageWidget;
      if (uri != null && uri.scheme == 'file') {
        imageWidget = Image.file(File(uri.toFilePath()), fit: BoxFit.cover);
      } else if (uri != null && uri.scheme == 'asset') {
        imageWidget = Image.asset(uri.path.replaceFirst('/', ''), fit: BoxFit.cover);
      } else {
        imageWidget = const Icon(Icons.music_note, size: 100);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 240,
              child: imageWidget,
            ),
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
                      //_buildArt(),
                      _buildArtWithInfo(),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (player.sequence != null &&
                                    audioProv.currentIndex <
                                        player.sequence.length) ...[
                                  Text(
                                    (player.sequence[audioProv.currentIndex].tag
                                            as MediaItem)
                                        .title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    (player.sequence[audioProv.currentIndex].tag
                                                as MediaItem)
                                            .album ??
                                        '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => favProv.toggle(songPath),
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      // Title & Artist
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      audioProv.shuffle
                          ? Icons.shuffle_outlined
                          : Icons.shuffle_on_outlined,
                    ),
                    onPressed: () => audioProv.toggleShuffle(),
                  ),
                  IconButton(
                    icon: Icon(
                      audioProv.repeatMode == LoopMode.one
                          ? Icons.repeat_one
                          : audioProv.repeatMode == LoopMode.all
                          ? Icons.repeat
                          : Icons.repeat_on_outlined,
                    ),
                    onPressed: () => audioProv.cycleRepeatMode(),
                  ),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.background,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => const EqualizerBottomSheet(),
                      );
                    },
                    icon: Icon(Icons.equalizer_outlined),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 0),

            // Seek bar + times
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                        ),
                      ),
                      child: Slider(
                        min: 0,
                        max: dur.inMilliseconds.toDouble(),
                        value: pos.inMilliseconds
                            .clamp(0, dur.inMilliseconds)
                            .toDouble(),
                        onChanged: (ms) =>
                            player.seek(Duration(milliseconds: ms.round())),
                        activeColor: Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(pos)),
                          Text(_formatDuration(dur)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 15),

            MainPlayControls(),

            const SizedBox(height: 7),

            SongsQueueList(),

          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final twoDig = (int n) => n.toString().padLeft(2, '0');
    final mins = twoDig(d.inMinutes.remainder(60));
    final secs = twoDig(d.inSeconds.remainder(60));
    return '$mins:$secs';
  }
}
