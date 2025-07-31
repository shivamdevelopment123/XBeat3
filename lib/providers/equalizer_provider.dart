// lib/providers/equalizer_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerProvider extends ChangeNotifier {
  // Frequencies in Hz we'll control
  static const List<int> bands = [60, 230, 910, 3600, 14000];

  // Key for SharedPreferences
  static const String _prefsKey = 'equalizer_gains';

  /// band -> gain in dB, from -12 to +12
  Map<int, double> _gains = {
    for (var f in bands) f: 0.0,
  };

  Map<int,double> get gains => Map.from(_gains);

  EqualizerProvider() {
    _loadFromPrefs();
  }

  /// Load saved gains (or leave flat if none)
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null) {
      final Map<String, dynamic> m = Map.from(await Future.value(
          (jsonDecode(json) as Map).map((k, v) => MapEntry(k as String, v))));
      _gains = {
        for (var entry in m.entries) int.parse(entry.key): (entry.value as num).toDouble()
      };
      notifyListeners();
    }
  }

  /// Save current gains
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(
      _gains.map((k, v) => MapEntry(k.toString(), v)),
    );
    await prefs.setString(_prefsKey, json);
  }

  /// Update a single band's gain
  void setGain(int freq, double db) {
    _gains[freq] = db;
    _saveToPrefs();
    notifyListeners();
  }

  /// Reset all bands to 0dB
  void reset() {
    for (var f in bands) {
      _gains[f] = 0.0;
    }
    _saveToPrefs();
    notifyListeners();
  }

  /// Presets
  static const Map<String, Map<int,double>> presets = {
    'Flat':       {60:0,   230:0,   910:0,    3600:0,    14000:0},
    'Pop':        {60: -1, 230: 2, 910: 4, 3600: -1,  14000: -1},
    'Rock':       {60: 4,  230: 2, 910: -2, 3600: 2,   14000: 4},
    'Jazz':       {60: 0,  230: 3, 910: 0,  3600: 3,   14000: 0},
    'Classical':  {60: -2, 230: -1,910: 3, 3600: 4,   14000: 2},
  };

  String _selectedPreset = 'Flat';
  String get selectedPreset => _selectedPreset;

  /// Apply a preset by name
  void applyPreset(String name) {
    final p = presets[name];
    if (p != null) {
      _selectedPreset = name;
      _gains = Map.from(p);
      _saveToPrefs();
      notifyListeners();
    }
  }
}
