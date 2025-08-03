class PresetData {
  final Map<int, double> gains;

  PresetData({required this.gains});

  Map<String, dynamic> toJson() => {
    'gains': gains.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory PresetData.fromJson(Map<String, dynamic> json) {
    final gainsJson = Map<String, dynamic>.from(json['gains']);
    return PresetData(
      gains: Map.fromEntries(
        gainsJson.entries.map(
              (e) => MapEntry(
            int.parse(e.key),
            (e.value as num).toDouble(),
          ),
        ),
      ),
    );
  }
}