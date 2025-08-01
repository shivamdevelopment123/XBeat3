import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

class MediaMetadataService {
  /// Reads metadata from a file at [path].
  static Future<Metadata?> fetchMetadata(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await MetadataRetriever.fromFile(file);
    } catch (e) {
      // handle/ log error as needed
      return null;
    }
  }
}
