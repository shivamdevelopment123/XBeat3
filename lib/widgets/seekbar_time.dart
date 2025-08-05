import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';

class SeekbarTime extends StatelessWidget {
  const SeekbarTime({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player = audioProv.player;

    return  StreamBuilder<Duration>(
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
                inactiveColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
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
    );
  }
  String _formatDuration(Duration d) {
    final twoDig = (int n) => n.toString().padLeft(2, '0');
    final mins = twoDig(d.inMinutes.remainder(60));
    final secs = twoDig(d.inSeconds.remainder(60));
    return '$mins:$secs';
  }
}
