import 'dart:convert';

enum ScanType { url, whatsapp, wifi, phone, email, text }

class ScanHistoryModel {
  final String value;
  final DateTime time;
  final ScanType type;
  bool isFavorite;

  ScanHistoryModel({
    required this.value,
    required this.time,
    required this.type,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
    'value': value,
    'time': time.toIso8601String(),
    'type': type.name,
    'isFavorite': isFavorite,
  };

  factory ScanHistoryModel.fromMap(Map<String, dynamic> map) {
    return ScanHistoryModel(
      value: map['value'],
      time: DateTime.parse(map['time']),
      type: ScanType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ScanType.text,
      ),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  static String encode(List<ScanHistoryModel> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  static List<ScanHistoryModel> decode(String data) =>
      (jsonDecode(data) as List)
          .map((e) => ScanHistoryModel.fromMap(e))
          .toList();
}
