import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/neu_box.dart';
import '../providers/audio_player_provider.dart';

class MainPlayControls extends StatelessWidget {
  const MainPlayControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player    = audioProv.player;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: GestureDetector(
              onTap: audioProv.hasPrevious ? () => audioProv.skipToPrevious() : null,
              child: NeuBox(
                child: Icon(
                  Icons.skip_previous,
                  size: 30,
                  color: audioProv.hasPrevious ? Theme.of(context).colorScheme.inverseSurface : Colors.grey.shade600,
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
                return GestureDetector(
                  onTap: () => playing ? audioProv.pause() : audioProv.play(),
                  child: NeuBox(
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
            child: GestureDetector(
              onTap: audioProv.hasNext ? () => audioProv.skipToNext() : null,
              child: NeuBox(
                child: Icon(
                  Icons.skip_next,
                  size: 30,
                  color: audioProv.hasNext ? Theme.of(context).colorScheme.inverseSurface : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
