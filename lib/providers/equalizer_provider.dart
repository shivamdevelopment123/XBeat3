import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/present_data.dart';

class EqualizerProvider extends ChangeNotifier {
  // Supported bands
  static const List<int> bands = [60, 230, 910, 3600, 14000];

  // Friendly labels
  static const Map<int, String> bandLabels = {
    60: 'Sub-Bass (60 Hz)',
    230: 'Bass (230 Hz)',
    910: 'Lower Mid (910 Hz)',
    3600: 'Upper Mid (3.6 kHz)',
    14000: 'Treble (14 kHz)',
  };

  // SharedPreferences keys
  static const String _gainsKey = 'equalizer_gains';
  static const String _presetKey = 'equalizer_selected_preset';
  static const String _userPresetsKey = 'equalizer_user_presets';

  // Defaults
  static const double defaultGain = 0.0;

  // Built-in presets (gain-only)
  static const Map<String, Map<int, double>> _builtInGains = {
    'Flat': {60: 0, 230: 0, 910: 0, 3600: 0, 14000: 0},
    'Pop': {60: -2, 230: -1, 910: 3, 3600: 1, 14000: -2},
    'Rock': {60: 3, 230: 1, 910: -1, 3600: 3, 14000: 4},
    'Jazz': {60: 3, 230: 0, 910: 2, 3600: 1, 14000: 2},
    'Classical': {60: 2, 230: 2, 910: 2, 3600: 2, 14000: 2},
    'Bass Boost': {60: 6, 230: 4, 910: -2, 3600: 0, 14000: 0},
    'Treble Boost': {60: -4, 230: -2, 910: 0, 3600: 4, 14000: 6},
    'Dance/EDM': {60: 5, 230: 3, 910: -2, 3600: 0, 14000: 5},
    'Hip-Hop': {60: 5, 230: 3, 910: 2, 3600: 1, 14000: 2},
    'Vocal Booster': {60: -3, 230: -1, 910: 4, 3600: 3, 14000: 1},
    'Background': {60: -3, 230: -2, 910: 2, 3600: 1, 14000: -2},
  };

  Map<int, double> _gains = {for (var f in bands) f: defaultGain};
  String _selectedPreset = 'Flat';
  Map<String, PresetData> userPresets = {};

  EqualizerProvider() { _loadFromPrefs(); }

  // Public getters
  Map<int, double> get gains => Map.from(_gains);
  String get selectedPreset => _selectedPreset;
  List<String> get builtInPresets => _builtInGains.keys.toList();
  List<String> get userPresetNames => userPresets.keys.toList();
  List<String> get allPresetNames => [...builtInPresets, ...userPresetNames, 'Custom'];

  /// Load state from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Gains
    final gJson = prefs.getString(_gainsKey);
    if (gJson != null) {
      final map = Map<String, dynamic>.from(jsonDecode(gJson));
      _gains = { for (var e in map.entries) int.parse(e.key): (e.value as num).toDouble() };
    }
    // Selected preset
    final preset = prefs.getString(_presetKey);
    if (preset != null) _selectedPreset = preset;
    // User presets
    final uJson = prefs.getString(_userPresetsKey);
    if (uJson != null) {
      final map = Map<String, dynamic>.from(jsonDecode(uJson));
      userPresets = map.map((k, v) => MapEntry(k, PresetData.fromJson(Map<String, dynamic>.from(v))));
    }
    notifyListeners();
  }

  /// Save state to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gainsKey, jsonEncode(_gains.map((k,v) => MapEntry(k.toString(), v))));
    await prefs.setString(_presetKey, _selectedPreset);
    await prefs.setString(_userPresetsKey, jsonEncode(userPresets.map((k,v) => MapEntry(k, v.toJson()))));
  }

  /// Adjust a single band gain
  void setGain(int freq, double db) {
    _gains[freq] = db;
    if (_selectedPreset != 'Custom') _selectedPreset = 'Custom';
    _saveToPrefs();
    notifyListeners();
  }

  /// Reset to Flat
  void reset() {
    _gains = Map.from(_builtInGains['Flat']!);
    _selectedPreset = 'Flat';
    _saveToPrefs();
    notifyListeners();
  }

  /// Apply a preset by name
  void applyPreset(String name) {
    if (_builtInGains.containsKey(name)) {
      _gains = Map.from(_builtInGains[name]!);
    } else if (userPresets.containsKey(name)) {
      _gains = Map.from(userPresets[name]!.gains);
    }
    _selectedPreset = name;
    _saveToPrefs();
    notifyListeners();
  }

  /// Save current as named user preset
  Future<void> saveUserPreset(String name) async {
    userPresets[name] = PresetData(gains: Map.from(_gains));
    _selectedPreset = name;
    await _saveToPrefs();
    notifyListeners();
  }

  /// Delete a user preset
  Future<void> deleteUserPreset(String name) async {
    userPresets.remove(name);
    if (_selectedPreset == name) reset();
    await _saveToPrefs();
    notifyListeners();
  }
}


