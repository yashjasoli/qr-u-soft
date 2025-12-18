import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan_history_model.dart';

Future<File> exportHistory(List<ScanHistoryModel> history) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/scan_history.txt');

  final content = history.map((e) {
    return '''
Value: ${e.value}
Type: ${e.type.name}
Time: ${e.time}
Favorite: ${e.isFavorite}
------------------------
''';
  }).join();

  return file.writeAsString(content);
}
