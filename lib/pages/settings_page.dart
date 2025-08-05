import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/themes/theme_provider.dart';

import '../providers/audio_player_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final audioProv = context.watch<AudioPlayerProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('S E T T I N G S'),
        elevation: 1,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Select Theme:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<ThemeMode>(
                    value: themeProv.themeMode,
                    dropdownColor: Theme.of(context).colorScheme.secondary,
                    iconEnabledColor: Theme.of(context).colorScheme.inversePrimary,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                    ),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light Mode'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark Mode'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) themeProv.setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Remember last-played track',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: audioProv.saveLastPlayedEnabled,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: audioProv.setSaveLastPlayedEnabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

