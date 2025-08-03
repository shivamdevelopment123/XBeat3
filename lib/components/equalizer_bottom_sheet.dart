import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equalizer_provider.dart';
import '../providers/audio_player_provider.dart';

class EqualizerBottomSheet extends StatelessWidget {
  const EqualizerBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eqProv = context.watch<EqualizerProvider>();
    final audioProv = context.read<AudioPlayerProvider>();
    final builtins = eqProv.builtInPresets;
    final users = eqProv.userPresetNames;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preset selector row
            Row(
              children: [
                const Text('Preset:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: eqProv.selectedPreset,
                    items: [
                      ...builtins.map((n) => DropdownMenuItem(value: n, child: Text(n))),
                      if (users.isNotEmpty) const DropdownMenuItem(enabled: false, child: Divider()),
                      ...users.map((n) => DropdownMenuItem(value: n, child: Text(n))),
                      const DropdownMenuItem(enabled: false, child: Divider()),
                      const DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                    ],
                    onChanged: (v) {
                      if (v == null || v == 'Custom') return;
                      eqProv.applyPreset(v);
                      audioProv.setEqualizer(eqProv.gains);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (eqProv.selectedPreset == 'Custom')
                  IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: 'Save Preset',
                    onPressed: () async {
                      final name = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          String temp = '';
                          return AlertDialog(
                            title: const Text('Save Custom Preset'),
                            content: TextField(
                              decoration: const InputDecoration(labelText: 'Preset Name'),
                              onChanged: (v) => temp = v.trim(),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('Save')),
                            ],
                          );
                        },
                      );
                      if (name?.isNotEmpty ?? false) {
                        await eqProv.saveUserPreset(name!);
                        audioProv.setEqualizer(eqProv.gains);
                      }
                    },
                  ),
                if (users.contains(eqProv.selectedPreset))
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Preset',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Preset'),
                          content: Text('Delete "\${eqProv.selectedPreset}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await eqProv.deleteUserPreset(eqProv.selectedPreset);
                        audioProv.setEqualizer(eqProv.gains);
                      }
                    },
                  ),
                TextButton(
                  onPressed: () {
                    eqProv.reset();
                    audioProv.setEqualizer(eqProv.gains);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sliders for each band
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: EqualizerProvider.bands.map((freq) {
                final gain = eqProv.gains[freq]!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gain display
                    Text('${gain.toStringAsFixed(1)} dB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    // Gain slider
                    SizedBox(
                      width: 40,
                      height: 250,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Slider(
                          min: -12,
                          max: 12,
                          divisions: 48,
                          value: gain,
                          onChanged: (v) {
                            eqProv.setGain(freq, v);
                            audioProv.setEqualizer(eqProv.gains);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Label
                    SizedBox(
                      height: 50,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          EqualizerProvider.bandLabels[freq]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
