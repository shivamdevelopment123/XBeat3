import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/audio_player_provider.dart';


class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player    = audioProv.player;

    Widget _buildArt() {
      final seq = player.sequence;
      if (seq == null || audioProv.currentIndex >= seq.length) {
        return const SizedBox(
          width: 250,
          height: 250,
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
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, size: 100),
            ),
          );
        } else if (uri.scheme == 'asset') {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              uri.path.replaceFirst('/', ''), // remove leading slash
              width: 250,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, size: 100),
            ),
          );
        }
      }

      return const SizedBox(
        width: 250,
        height: 250,
        child: Icon(Icons.music_note, size: 100),
      );
    }


    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: Icon(
              audioProv.shuffle ? Icons.shuffle_on : Icons.shuffle,
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildArt(),
            const SizedBox(height: 24),

            // Title & Artist
            if (player.sequence != null && audioProv.currentIndex < player.sequence!.length) ...[
              Text(
                (player.sequence![audioProv.currentIndex].tag as MediaItem).title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                (player.sequence![audioProv.currentIndex].tag as MediaItem).album ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],

            const Spacer(),

            // Seek bar + times
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = player.duration ?? Duration.zero;
                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: dur.inMilliseconds.toDouble(),
                      value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
                      onChanged: (ms) => player.seek(Duration(milliseconds: ms.round())),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

            const SizedBox(height: 24),

            // Playback controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: audioProv.hasPrevious
                        ? () => audioProv.skipToPrevious()
                        : null,
                  ),

                  // Play/Pause
                  StreamBuilder<bool>(
                    stream: player.playingStream,
                    initialData: player.playing,
                    builder: (context, snap) {
                      final playing = snap.data!;
                      return IconButton(
                        iconSize: 64,
                        icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                        onPressed: () => playing ? audioProv.pause() : audioProv.play(),
                      );
                    },
                  ),

                  // Next
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next),
                    onPressed: audioProv.hasNext
                        ? () => audioProv.skipToNext()
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
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