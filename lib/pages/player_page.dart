import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/components/neu_box.dart';
import 'package:xbeat3/widgets/main_play_controls.dart';
import 'package:xbeat3/widgets/middle_modification_controls.dart';
import 'package:xbeat3/widgets/seekbar_time.dart';
import 'package:xbeat3/widgets/title_artist_playerpage.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/song_info_sheet.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final audioProv = context.watch<AudioPlayerProvider>();
    final player = audioProv.player;
    final seq = player.sequence;

    if (seq == null || seq.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('N O W     P L A Y I N G'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentIndex = audioProv.currentIndex.clamp(0, seq.length - 1);
    final mediaItem = seq[currentIndex].tag as MediaItem;
    final songPath = mediaItem.id;
    final nextSongs = (seq == null || currentIndex >= seq.length - 1)
        ? []
        : seq.sublist(currentIndex + 1);

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
                      backgroundColor: Theme.of(context).colorScheme.surface,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('N O W      P L A Y I N G'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: const SizedBox(height: 15)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(

                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      if (audioProv.hasNext) audioProv.skipToNext();
                    } else if (details.primaryVelocity! > 0) {
                      if (audioProv.hasPrevious) audioProv.skipToPrevious();
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
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 15)),
            SliverToBoxAdapter(child: MiddleModificationControls()),
            SliverToBoxAdapter(child: SeekbarTime()),
            SliverToBoxAdapter(child: const SizedBox(height: 15)),
            SliverToBoxAdapter(child: MainPlayControls()),
            SliverToBoxAdapter(child: const SizedBox(height: 7)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final mediaItem = nextSongs[index].tag as MediaItem;
                    final actualIndex = currentIndex + 1 + index;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.music_note, size: 20),
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
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              context: context,
                              builder: (ctx) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
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
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const Divider(height: 1, thickness: 0.4),
                      ],
                    );
                  },
                  childCount: nextSongs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
