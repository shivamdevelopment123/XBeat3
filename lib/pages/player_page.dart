import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xbeat3/components/neu_box.dart';
import '../providers/audio_player_provider.dart';
import '../providers/favourite_provider.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player    = audioProv.player;
    final mediaItem = player.sequence[audioProv.currentIndex].tag as MediaItem;
    final songPath = mediaItem.id;
    final favProv = context.watch<FavouriteProvider>();
    final isFav   = favProv.isFav(songPath);

    Widget _buildArt(){
      final seq = player.sequence;
      if (seq == null || audioProv.currentIndex >= seq.length) {
        return const SizedBox(
          width: double.infinity,
          height: 240,
          child: Icon(Icons.music_note, size: 100),
        );
      }

      final mediaItem = seq[audioProv.currentIndex].tag as MediaItem?;
      if (mediaItem?.artUri != null) {
        final uri = mediaItem!.artUri!;
        if (uri.scheme == 'file') {
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
        } else if (uri.scheme == 'asset') {
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
      }

      return const SizedBox(
        width: double.infinity,
        height: 240,
        child: Icon(Icons.music_note, size: 100),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Now Playing'),
        actions: [

        ],
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
                      _buildArt(),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (player.sequence != null && audioProv.currentIndex < player.sequence.length) ...[
                                  Text(
                                    (player.sequence[audioProv.currentIndex].tag as MediaItem).title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    (player.sequence[audioProv.currentIndex].tag as MediaItem).album ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                          //Icon(Icons.favorite_border, color: Colors.red,)
                        ]
                      ),
                      // Title & Artist
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      audioProv.shuffle ? Icons.shuffle_outlined : Icons.shuffle_on_outlined,
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
                      onPressed: (){},
                      icon: Icon(Icons.equalizer_outlined))
                ],
              ),
            ),


            const SizedBox(height: 0,),

            // Seek bar + times
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;
                return Column(
                  children: [
                    SliderTheme(
                      data : SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                      ),
                      child: Slider(
                        min: 0,
                        max: dur.inMilliseconds.toDouble(),
                        value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                        onChanged: (ms) => player.seek(Duration(milliseconds: ms.round())),
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

            const SizedBox(height: 15,),

            // Playback controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Previous
                  Expanded(
                    child: NeuBox(
                      child: GestureDetector(
                        onTap: audioProv.hasPrevious ? () => audioProv.skipToPrevious() : null,
                        child: Icon(
                          Icons.skip_previous,
                          size: 30,
                          color: audioProv.hasPrevious ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 15,),

                  // Play/Pause
                  Expanded(
                    child: StreamBuilder<bool>(
                      stream: player.playingStream,
                      initialData: player.playing,
                      builder: (context, snap) {
                        final playing = snap.data!;
                        return NeuBox(
                          child: GestureDetector(
                            onTap: () => playing ? audioProv.pause() : audioProv.play(),
                            child: Icon(
                              playing ? Icons.pause : Icons.play_arrow,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 15,),

                  // Next
                  Expanded(
                    child: NeuBox(
                      child: GestureDetector(
                        onTap: audioProv.hasNext ? () => audioProv.skipToNext() : null,
                        child: Icon(
                          Icons.skip_next,
                          size: 30,
                          color: audioProv.hasNext ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10,),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<SequenceState?>(
              stream: audioProv.player.sequenceStateStream,
              builder: (context, snapshot) {
                final seq = snapshot.data?.sequence;
                final currentIndex = audioProv.currentIndex;

                if (seq == null || currentIndex >= seq.length - 1) {
                  return const Center(
                    child: Text(
                      "No upcoming songs in queue.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final nextSongs = seq.sublist(currentIndex + 1);

                return ListView.separated(
                  itemCount: nextSongs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final mediaItem = nextSongs[index].tag as MediaItem;
                    final actualIndex = currentIndex + 1 + index;

                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(
                        mediaItem.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        mediaItem.album ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        audioProv.skipToQueueItem(actualIndex);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
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