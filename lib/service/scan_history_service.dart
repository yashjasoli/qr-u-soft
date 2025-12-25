import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_model.dart';
import '../utils/scan_type_detector.dart';

class ScanHistoryService {
  static const String _key = "SCAN_HISTORY_V2";

  // 📥 GET HISTORY
  Future<List<ScanHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return ScanHistoryModel.decode(raw);
  }

  // 💾 SAVE NEW SCAN
  Future<void> saveScan(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

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

  // ⭐ TOGGLE FAVORITE
  Future<void> toggleFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    if (index < 0 || index >= list.length) return;

    list[index].isFavorite = !list[index].isFavorite;
    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  // ✏️ UPDATE ITEM (IMPORTANT)
  Future<void> updateAt(int index, ScanHistoryModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    if (index < 0 || index >= list.length) return;

    list[index] = model;
    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  // 🗑 DELETE ITEM
  Future<void> deleteAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    if (index < 0 || index >= list.length) return;

    list.removeAt(index);
    await prefs.setString(_key, ScanHistoryModel.encode(list));
  }

  // 🧹 CLEAR ALL
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
