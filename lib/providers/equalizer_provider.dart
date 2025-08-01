import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/present_data.dart';

class EqualizerProvider extends ChangeNotifier {
  // Frequencies in Hz we'll control
  static const List<int> bands = [60, 230, 910, 3600, 14000];

  // Friendly labels for each band
  static const Map<int, String> bandLabels = {
    60: 'Sub-Bass (60 Hz)',
    230: 'Bass (230 Hz)',
    910: 'Lower Mid (910 Hz)',
    3600: 'Upper Mid (3.6 kHz)',
    14000: 'Treble (14 kHz)',
  };

  // SharedPreferences keys
  static const String _gainsKey = 'equalizer_gains';
  static const String _qsKey = 'equalizer_qs';
  static const String _presetKey = 'equalizer_selected_preset';
  static const String _userPresetsKey = 'equalizer_user_presets';

  // Default values
  static const double defaultGain = 0.0;
  static const double defaultQ = 1.0;

  // Internal state
  Map<int, double> _gains = {for (var f in bands) f: defaultGain};
  Map<int, double> _qs = {for (var f in bands) f: defaultQ};
  String _selectedPreset = 'Flat';

  /// Built-in presets (gain only), Q defaults to 1.0
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

  // User-defined presets (gains + q)
  Map<String, PresetData> userPresets = {};

  EqualizerProvider() {
    _loadFromPrefs();
  }

  Map<int, double> get gains => Map.from(_gains);
  Map<int, double> get qFactors => Map.from(_qs);
  String get selectedPreset => _selectedPreset;

  List<String> get userPresetNames => userPresets.keys.toList();
  List<String> get builtInPresets => _builtInGains.keys.toList();
  List<String> get allPresetNames => [
    ...builtInPresets,
    ...userPresets.keys,
    'Custom',
  ];

  /// Load saved gains, qs, selected preset, and user presets
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Gains
    final jsonGains = prefs.getString(_gainsKey);
    if (jsonGains != null) {
      final m = Map<String, dynamic>.from(jsonDecode(jsonGains));
      _gains = {for (var e in m.entries) int.parse(e.key): (e.value as num).toDouble()};
    }

    // Q factors
    final jsonQs = prefs.getString(_qsKey);
    if (jsonQs != null) {
      final m = Map<String, dynamic>.from(jsonDecode(jsonQs));
      _qs = {for (var e in m.entries) int.parse(e.key): (e.value as num).toDouble()};
    }

    // Selected preset
    final savedPreset = prefs.getString(_presetKey);
    if (savedPreset != null) {
      _selectedPreset = savedPreset;
    }

    // User presets
    final jsonUser = prefs.getString(_userPresetsKey);
    if (jsonUser != null) {
      final m = Map<String, dynamic>.from(jsonDecode(jsonUser));
      userPresets = m.map((k, v) => MapEntry(k, PresetData.fromJson(Map<String, dynamic>.from(v))));
    }

    notifyListeners();
  }

  /// Save gains, qs, selected preset, and user presets
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gainsKey, jsonEncode(
        _gains.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString(_qsKey, jsonEncode(
        _qs.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString(_presetKey, _selectedPreset);
    await prefs.setString(_userPresetsKey, jsonEncode(
        userPresets.map((k, v) => MapEntry(k, v.toJson()))));
  }

  /// Update gain and switch to Custom
  void setGain(int freq, double db) {
    _gains[freq] = db;
    if (!_isCustom) {
      _selectedPreset = 'Custom';
    }
    _saveToPrefs();
    notifyListeners();
  }

  /// Update Q and switch to Custom
  void setQ(int freq, double q) {
    _qs[freq] = q;
    if (!_isCustom) {
      _selectedPreset = 'Custom';
    }
    _saveToPrefs();
    notifyListeners();
  }

  bool get _isCustom => _selectedPreset == 'Custom';

  /// Reset to Flat
  void reset() {
    _gains = Map.from(_builtInGains['Flat']!);
    _qs = {for (var f in bands) f: defaultQ};
    _selectedPreset = 'Flat';
    _saveToPrefs();
    notifyListeners();
  }

  /// Apply built-in or user preset
  void applyPreset(String name) {
    if (_builtInGains.containsKey(name)) {
      _gains = Map.from(_builtInGains[name]!);
      _qs = {for (var f in bands) f: defaultQ};
    } else if (userPresets.containsKey(name)) {
      final p = userPresets[name]!;
      _gains = Map.from(p.gains);
      _qs = Map.from(p.qs);
    }
    _selectedPreset = name;
    _saveToPrefs();
    notifyListeners();
  }

  /// Save current Custom as a new user preset
  Future<void> saveUserPreset(String name) async {
    userPresets[name] = PresetData(gains: Map.from(_gains), qs: Map.from(_qs));
    _selectedPreset = name;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteUserPreset(String name) async {
    userPresets.remove(name);
    if (_selectedPreset == name) reset();
    await _saveToPrefs();
    notifyListeners();
  }
}

