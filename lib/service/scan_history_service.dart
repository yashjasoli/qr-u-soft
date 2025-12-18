import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_model.dart';
import '../utils/scan_type_detector.dart';

class ScanHistoryService {
  static const String _key = "SCAN_HISTORY_V2";

  Future<List<ScanHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return ScanHistoryModel.decode(raw);
  }

  Future<void> saveScan(String value) async {
    final prefs = await SharedPreferences.getInstance();
    List<ScanHistoryModel> list = await getHistory();

    list.insert(
      0,
      ScanHistoryModel(
        value: value,
        time: DateTime.now(),
        type: detectScanType(value),
      ),
    );

    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  Future<void> toggleFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<ScanHistoryModel> list = await getHistory();

    list[index].isFavorite = !list[index].isFavorite;
    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<ScanHistoryModel> list = await getHistory();

    list.removeAt(index);
    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
