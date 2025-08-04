import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';
class SongsQueueList extends StatelessWidget {
  const SongsQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();

    return Padding(
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

          return Column(
            children: List.generate(nextSongs.length, (index) {
              final mediaItem = nextSongs[index].tag as MediaItem;
              final actualIndex = currentIndex + 1 + index;

              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
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
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.queue_play_next),
                                  title: const Text('Play Next'),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await audioProv.playNext(
                                      mediaItem.id,
                                      mediaItem,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Remove from Queue'),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    await audioProv.removeFromQueue(actualIndex);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 0.0, thickness: 0.4),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}
