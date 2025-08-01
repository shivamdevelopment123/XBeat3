import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../services/media_metadata.dart';

class SongInfoSheet extends StatelessWidget {
  final String songPath;
  final String title;
  final String album;
  final String artist;

  const SongInfoSheet({
    super.key,
    required this.songPath,
    required this.title,
    required this.album,
    required this.artist,
  });

  Future<Metadata?> _fetchMetadata() async {
    return await MediaMetadataService.fetchMetadata(songPath);
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Metadata?>(
        future: _fetchMetadata(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final meta = snap.data;

          final stat = File(songPath).statSync();
          final fileSizeMB = (stat.size / (1024 * 1024))
              .toStringAsFixed(2) + ' MB';
          final kbps = meta?.bitrate != null
              ? '${(meta!.bitrate! / 1000).toStringAsFixed(1)} kbps'
              : null;
          final discNo = meta?.discNumber?.toString();
          final albumLen = meta?.albumLength?.toString();
          final author    = meta?.authorName;
          final writer    = meta?.writerName;
          final mime      = meta?.mimeType;

          // format date-only
          final createdDate = stat.changed
              .toLocal()
              .toIso8601String()
              .split('T')
              .first;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    'Song Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Core
                _infoRow('Title', title),
                _infoRow('Artist', artist),
                _infoRow('Album', album),

                // Extra
                if (kbps      != null) _infoRow('Bitrate',   kbps),
                if (meta?.trackDuration != null)
                  _infoRow(
                    'Duration',
                    Duration(milliseconds: meta!.trackDuration!)
                        .toString()
                        .split('.')
                        .first,
                  ),
                if (meta?.genre       != null) _infoRow('Genre',      meta!.genre!),
                if (discNo    != null) _infoRow('Disc #',     discNo),
                if (albumLen  != null) _infoRow('Album Length', albumLen),
                if (author    != null) _infoRow('Author',     author),
                if (writer    != null) _infoRow('Writer',     writer),
                if (mime      != null) _infoRow('MIME Type',  mime),

                // File info
                _infoRow('File Size',  fileSizeMB),
                _infoRow('Created On', createdDate),

                const SizedBox(height: 18),
                // Close

              ],
            ),
          );
        },
      ),
    );
  }
}


