class PresetData {
  final Map<int, double> gains;
  final Map<int, double> qs;

  PresetData({required this.gains, required this.qs});

  Map<String, dynamic> toJson() => {
    'gains': gains.map((k, v) => MapEntry(k.toString(), v)),
    'qs': qs.map((k, v) => MapEntry(k.toString(), v)),
  };

  factory PresetData.fromJson(Map<String, dynamic> json) {
    final gainsJson = Map<String, dynamic>.from(json['gains']);
    final qsJson = Map<String, dynamic>.from(json['qs']);

    return PresetData(
      gains: gainsJson.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
      qs: qsJson.map((k, v) => MapEntry(int.parse(k), (v as num).toDouble())),
    );
  }
}