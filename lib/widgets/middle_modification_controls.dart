import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../components/equalizer_bottom_sheet.dart';
import '../providers/audio_player_provider.dart';

class MiddleModificationControls extends StatelessWidget {
  const MiddleModificationControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: audioProv.shuffle ? Colors.red : Colors.grey,
            ),
            onPressed: () => audioProv.toggleShuffle(),
          ),
    IconButton(
    icon: Icon(
    audioProv.repeatMode == LoopMode.one
    ? Icons.repeat_one
        : Icons.repeat,
    color: audioProv.repeatMode == LoopMode.off
    ? Colors.grey
        : Colors.red,
    ),
    onPressed: () => audioProv.cycleRepeatMode(),
    ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                builder: (_) => const EqualizerBottomSheet(),
              );
            },
            icon: Icon(Icons.equalizer_outlined, color: Colors.grey,),
          ),
        ],
      ),
    );
  }
}
