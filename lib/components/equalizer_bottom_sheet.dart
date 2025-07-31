// lib/widgets/equalizer_bottom_sheet.dart
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preset dropdown
            Row(
              children: [
                const Text('Preset:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: eqProv.selectedPreset,
                  items: EqualizerProvider.presets.keys
                      .map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      eqProv.applyPreset(v);
                      audioProv.setEqualizer(eqProv.gains);
                    }
                  },
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    eqProv.reset();
                    audioProv.setEqualizer(eqProv.gains);
                  },
                  child: const Text('Reset'),
                )
              ],
            ),

            const SizedBox(height: 16),

            // One slider per band
            ...EqualizerProvider.bands.map((freq) {
              final gain = eqProv.gains[freq]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$freq Hz (${gain.toStringAsFixed(1)} dB)'),
                  Slider(
                    min: -12,
                    max: 12,
                    divisions: 48,
                    value: gain,
                    onChanged: (v) {
                      eqProv.setGain(freq, v);
                      audioProv.setEqualizer(eqProv.gains);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}