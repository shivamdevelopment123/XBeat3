import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xbeat3/pages/home_page.dart';
import 'package:xbeat3/providers/audio_player_provider.dart';
import 'package:xbeat3/providers/equalizer_provider.dart';
import 'package:xbeat3/providers/favourite_provider.dart';
import 'package:xbeat3/providers/file_provider.dart';
import 'package:xbeat3/providers/folder_provider.dart';
import 'package:xbeat3/themes/dark_mode.dart';
import 'package:xbeat3/themes/light_mode.dart';
import 'package:xbeat3/themes/theme_provider.dart';
import 'package:xbeat3/utils/permission_utils.dart';
import 'package:xbeat3/utils/prefrences_util.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, s) {
      debugPrint("Error loading SharedPreferences: $e\n$s");
      prefs = null;
    }

    try {
      await Hive.initFlutter();
      await Hive.openBox<String>('favourites');
    } catch (e, s) {
      debugPrint("Error initializing Hive: $e\n$s");
    }

    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.sentiant.xbeat3.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidNotificationIcon: 'drawable/bingicon',
      );
      if (kDebugMode) print("JustAudioBackground initialized");
    } catch (e, s) {
      debugPrint("Error initializing JustAudioBackground: $e\n$s");
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => FolderProvider()),
          ChangeNotifierProvider(create: (_) => FileProvider()),
          ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
          ChangeNotifierProvider(create: (_) => FavouriteProvider()),
          ChangeNotifierProvider(create: (_) => EqualizerProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint("Uncaught error: $error\n$stack");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'An Audio Player',
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeProvider.themeMode,
          home: const PermissionsGate(),
        );
      },
    );
  }
}

class PermissionsGate extends StatefulWidget {
  const PermissionsGate({super.key});
  @override
  State<PermissionsGate> createState() => _PermissionsGateState();
}

class _PermissionsGateState extends State<PermissionsGate> {
  bool? _hasPermission; // null = still checking
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions({bool retry = false}) async {
    if (_isRequesting) return;
    _isRequesting = true;

    try {
      final granted = await PermissionUtils.requestAllPermissions()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("Permission request timed out");
        return false;
      });

      if (!mounted) return;

      if (!granted) {
        if (retry) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissions are required to proceed')),
          );
        }
        setState(() => _hasPermission = false);
        return;
      }

      // Permissions granted
      setState(() => _hasPermission = true);

      try {
        await context.read<FileProvider>().fetchFiles();
      } catch (e, s) {
        debugPrint("Error fetching files: $e\n$s");
      }

      try {
        final autoFetchEnabled = await PrefsUtils.getAutoFetchAudioEnabled();
        if (autoFetchEnabled) {
          debugPrint("Auto fetch enabled - starting scan");
          await context.read<FolderProvider>().autoFetchAudioFolders();
        }
      } catch (e, s) {
        debugPrint("Error auto-fetching audio folders: $e\n$s");
      }
    } catch (e, s) {
      debugPrint("Error in _checkPermissions: $e\n$s");
      setState(() => _hasPermission = false);
    } finally {
      _isRequesting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("XBeat3", style: TextStyle(color: Colors.white70, fontSize: 36),),
        ),
      );
    }

    if (_hasPermission == false) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => _checkPermissions(retry: true),
            child: const Text(
              'Enable storage permission',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );
    }

    // Permission granted
    return const HomePage();
  }
}


