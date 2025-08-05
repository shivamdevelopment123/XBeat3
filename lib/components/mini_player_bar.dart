import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/components/neu_box.dart';

import '../pages/player_page.dart';
import '../providers/audio_player_provider.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player    = audioProv.player;

    if (player.sequence == null || player.sequence!.isEmpty) {
      return const SizedBox.shrink();
    }

    final mediaItem = player.sequence![audioProv.currentIndex].tag as MediaItem;
    final title = mediaItem.title;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerPage()),
        );
      },
      child: NeuBox(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Row(
            children: [
              // Track title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: audioProv.hasPrevious
                    ? () => audioProv.skipToPrevious()
                    : null,
              ),

              StreamBuilder<bool>(
                stream: player.playingStream,
                initialData: player.playing,
                builder: (context, snap) {
                  final playing = snap.data!;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: () =>
                    playing ? audioProv.pause() : audioProv.play(),
                  );
                },
              ),

              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: audioProv.hasNext
                    ? () => audioProv.skipToNext()
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
