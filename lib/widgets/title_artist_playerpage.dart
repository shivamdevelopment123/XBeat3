import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/audio_player_provider.dart';
import '../providers/favourite_provider.dart';

class TitleArtistPlayerpage extends StatelessWidget {
  final  String songPath;
  const TitleArtistPlayerpage({super.key, required this.songPath});

  @override
  Widget build(BuildContext context) {

    final audioProv = context.watch<AudioPlayerProvider>();
    final player = audioProv.player;
    final favProv = context.watch<FavouriteProvider>();
    final isFav = favProv.isFav(songPath);

    return Row(
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
    );
  }
}
