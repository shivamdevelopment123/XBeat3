import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/prefrences_util.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<String> _playlist = [];
  int _currentIndex = 0;
  bool _shuffle = false;
  LoopMode _repeatMode = LoopMode.off;

  static const _saveLastPlayedEnableKey = 'save_last_played_enabled';
  bool _saveLastPlayedEnabled = false;
  bool get saveLastPlayedEnabled => _saveLastPlayedEnabled;

  static const String _eqPrefsKey = 'equalizer_gains';
  Map<int,double> _eqGains = {};

  static const _eqChannel = MethodChannel('com.sentiant.xbeat3/equalizer');

  AudioPlayer get player => _player;
  int get currentIndex => _currentIndex;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  bool get isPlaying => _player.playing;
  bool get shuffle => _shuffle;
  LoopMode get repeatMode => _repeatMode;

  Future<void> setEqualizer(Map<int,double> gains) async {
    final sessionId = player.androidAudioSessionId;
    await _eqChannel.invokeMethod('setEQ', {
      'sessionId': sessionId ?? 0,
      'gains': gains.map((f, g) => MapEntry(f.toString(), g)),
    });
    if (kDebugMode) debugPrint('EQ → native: $gains');
  }

  AudioPlayerProvider() {
    _initEqualizer();
    _initLastPlayedRestore();

    _player.playingStream.listen((playing) {
      if (playing) {
        setEqualizer(_eqGains);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });

    _player.currentIndexStream.listen((index) async {
      if (index != null && index < _playlist.length) {
        _currentIndex = index;
        notifyListeners();

        if (_saveLastPlayedEnabled) {
          final currentUri = _playlist[_currentIndex];
          await PrefsUtils.saveLastPlayedSong(currentUri);
        }
      }
    });

  }

  Future<void> _initEqualizer() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_eqPrefsKey);
    if (jsonString != null) {
      final Map<String,dynamic> decoded = jsonDecode(jsonString);
      _eqGains = decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble()));
      if (kDebugMode) debugPrint('Loaded EQ gains: $_eqGains');
      await setEqualizer(_eqGains);
    }
  }

  Future<void> _initLastPlayedRestore() async {
    _saveLastPlayedEnabled = await PrefsUtils.getSaveLastPlayedEnabled();
    if (_saveLastPlayedEnabled) {
      final last = await PrefsUtils.getLastPlayedSong();
      if (last != null && File(last).existsSync()) {
        await setPlaylist([last], startIndex: 0, autoPlay: false);
        await pause();
      }
    }
  }

  Future<void> setSaveLastPlayedEnabled(bool enabled) async {
    _saveLastPlayedEnabled = enabled;
    await PrefsUtils.setSaveLastPlayedEnabled(enabled);
    notifyListeners();
  }

  Future<void> playNext(String uri, MediaItem mediaItem) async {
    final source = AudioSource.uri(Uri.file(uri), tag: mediaItem);
    final playlist = _player.audioSource as ConcatenatingAudioSource;

    int originalIndex = _playlist.indexOf(uri);

    if (originalIndex != -1 && originalIndex != _currentIndex + 1 && originalIndex != _currentIndex) {
      await playlist.removeAt(originalIndex);
      _playlist.removeAt(originalIndex);

      if (originalIndex < _currentIndex + 1) {
        _currentIndex--;
      }
    }

    int insertIndex = _currentIndex + 1;
    await playlist.insert(insertIndex, source);
    _playlist.insert(insertIndex, uri);

    notifyListeners();
  }

  Future<void> removeFromQueue(int index) async {
    final playlist = _player.audioSource as ConcatenatingAudioSource;

    if (index > _playlist.length - 1 || index < 0) return;

    await playlist.removeAt(index);
    _playlist.removeAt(index);

    notifyListeners();
  }

  Future<void> setPlaylist(List<String> uris, {int startIndex = 0,  bool autoPlay = true,}) async {
    _playlist = uris;
    _currentIndex = startIndex;

    final firstFile = File(uris[startIndex]);
    final metadata = await MetadataRetriever.fromFile(firstFile);

    final title = metadata.trackName ?? firstFile.path.split('/').last;
    final album = metadata.albumName ?? 'Unknown Album';
    final artist = metadata.trackArtistNames?.join(', ') ?? 'Unknown Artist';

    Uri artUri;
    final artwork = metadata.albumArt;

    if (artwork != null) {
      final tempDir = Directory.systemTemp;
      final artFile = File('${tempDir.path}/art_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await artFile.writeAsBytes(artwork);
      artUri = Uri.file(artFile.path);
    } else {
      final byteData = await rootBundle.load('assets/images/fallback.png');
      final fallbackArtFile = File('${Directory.systemTemp.path}/fallback_art.png');
      await fallbackArtFile.writeAsBytes(byteData.buffer.asUint8List());
      artUri = Uri.file(fallbackArtFile.path);
    }

    final mediaItem = MediaItem(
      id: uris[startIndex],
      album: album,
      title: title,
      artist: artist,
      artUri: artUri,
    );

    final initialSource = AudioSource.uri(
      Uri.file(uris[startIndex]),
      tag: mediaItem,
    );

    final playlistSource = ConcatenatingAudioSource(children: [initialSource]);
    await _player.setAudioSource(playlistSource, initialIndex: 0);

    notifyListeners();

    unawaited(_loadRemainingPlaylist(uris, skipIndex: startIndex));
    if (autoPlay) {
      await _player.play();
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipToNext() async {
    if (hasNext) {
      await _player.seekToNext();
      _currentIndex = _player.currentIndex!;
      notifyListeners();
    }
  }

  Future<void> _loadRemainingPlaylist(List<String> uris, {required int skipIndex}) async {
    final remainingSources = <AudioSource>[];

    for (int i = 0; i < uris.length; i++) {
      if (i == skipIndex) continue;

      final file = File(uris[i]);
      final metadata = await MetadataRetriever.fromFile(file);

      final title = metadata.trackName ?? file.path.split('/').last;
      final album = metadata.albumName ?? 'Unknown Album';
      final artist = metadata.trackArtistNames?.join(', ') ?? 'Unknown Artist';

      Uri artUri;
      final artwork = metadata.albumArt;

      if (artwork != null) {
        final tempDir = Directory.systemTemp;
        final artFile = File('${tempDir.path}/art_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await artFile.writeAsBytes(artwork);
        artUri = Uri.file(artFile.path);
      } else {
        final byteData = await rootBundle.load('assets/images/fallback.png');
        final fallbackArtFile = File('${Directory.systemTemp.path}/fallback_art_$i.png');
        await fallbackArtFile.writeAsBytes(byteData.buffer.asUint8List());
        artUri = Uri.file(fallbackArtFile.path);
      }

      final mediaItem = MediaItem(
        id: uris[i],
        album: album,
        title: title,
        artist: artist,
        artUri: artUri,
      );

      remainingSources.add(AudioSource.uri(Uri.file(uris[i]), tag: mediaItem));
    }

    final existing = _player.audioSource as ConcatenatingAudioSource;
    await existing.addAll(remainingSources);
    notifyListeners();
  }

  Future<void> skipToPrevious() async {
    if (hasPrevious) {
      await _player.seekToPrevious();
      _currentIndex = _player.currentIndex!;
      notifyListeners();
    }
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _player.setShuffleModeEnabled(_shuffle);

    Fluttertoast.showToast(
      msg: _shuffle ? "Shuffle On" : "Shuffle Off",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = LoopMode.values[(_repeatMode.index + 1) % LoopMode.values.length];
    _player.setLoopMode(_repeatMode);

    String modeName;
    switch (_repeatMode) {
      case LoopMode.off:
        modeName = "Repeat Off";
        break;
      case LoopMode.all:
        modeName = "Repeat All";
        break;
      case LoopMode.one:
        modeName = "Repeat One";
        break;
    }

    Fluttertoast.showToast(
      msg: modeName,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    notifyListeners();
  }

  void _handleTrackCompletion() {
    switch (_repeatMode) {
      case LoopMode.one:
        _player.seek(Duration.zero, index: _currentIndex);
        _player.play();
        break;
      case LoopMode.all:
        if (hasNext) {
          skipToNext();
          play();
        } else {
          _player.seek(Duration.zero, index: 0);
          _currentIndex = 0;
          play();
        }
        break;
      case LoopMode.off:
        if (_shuffle && _playlist.isNotEmpty) {
          final next = (List.generate(_playlist.length, (i) => i)..shuffle()).first;
          _player.seek(Duration.zero, index: next);
          _currentIndex = next;
          _player.play();
        } else if (hasNext) {
          skipToNext();
          play();
        }
        break;
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _player.seek(Duration.zero, index: index);
      _currentIndex = index;
      await _player.play();
      notifyListeners();
    }
  }

  void addToPlaylist(String uri) {
    _playlist.add(uri);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
