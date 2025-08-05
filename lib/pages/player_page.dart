import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

    // If no sequence, show loading UI
    if (seq == null || seq.isEmpty) {
      return _buildEmptyState(context);
    }

    // Ensure valid index
    final rawIndex = audioProv.currentIndex ?? 0;
    final currentIndex = rawIndex.clamp(0, seq.length - 1);

    // Safely extract current media item
    final tag = seq[currentIndex].tag;
    if (tag is! MediaItem) {
      return _buildEmptyState(context);
    }

    final songPath = tag.id;
    final nextSongs = (currentIndex >= seq.length - 1)
        ? const <IndexedAudioSource>[]
        : seq.sublist(currentIndex + 1);

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
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity == null) return;
                    if (details.primaryVelocity! < 0 && audioProv.hasNext) {
                      audioProv.skipToNext();
                    } else if (details.primaryVelocity! > 0 && audioProv.hasPrevious) {
                      audioProv.skipToPrevious();
                    }
                  },
                  child: NeuBox(
                    child: Column(
                      children: [
                        _buildArtWithInfo(context, tag),
                        const SizedBox(height: 10),
                        TitleArtistPlayerpage(songPath: songPath),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            const SliverToBoxAdapter(child: MiddleModificationControls()),
            const SliverToBoxAdapter(child: SeekbarTime()),
            const SliverToBoxAdapter(child: SizedBox(height: 15)),
            const SliverToBoxAdapter(child: MainPlayControls()),
            const SliverToBoxAdapter(child: SizedBox(height: 7)),

            if (nextSongs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: nextSongs.length,
                  itemBuilder: (context, index) {
                    final itemTag = nextSongs[index].tag;
                    if (itemTag is! MediaItem) return const SizedBox.shrink();

                    final actualIndex = currentIndex + 1 + index;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.music_note, size: 20),
                          title: Text(
                            itemTag.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            itemTag.album ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => audioProv.skipToQueueItem(actualIndex),
                          onLongPress: () => _showSongOptions(context, audioProv, itemTag, actualIndex),
                        ),
                        const Divider(height: 1, thickness: 0.4),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildArtWithInfo(BuildContext context, MediaItem item) {
    final uri = item.artUri;
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
                      songPath: item.id,
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

  void _showSongOptions(BuildContext context, AudioPlayerProvider audioProv, MediaItem mediaItem, int actualIndex) {
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
                    await audioProv.playNext(mediaItem.id, mediaItem);
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
  }
}
