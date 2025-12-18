import '../models/scan_history_model.dart';

ScanType detectScanType(String value) {
  final v = value.toLowerCase();

  if (v.startsWith('whatsapp://') || v.contains('wa.me')) {
    return ScanType.whatsapp;
  }
  if (v.startsWith('http://') || v.startsWith('https://')) {
    return ScanType.url;
  }
  if (v.startsWith('wifi:')) {
    return ScanType.wifi;
  }
  if (v.startsWith('tel:')) {
    return ScanType.phone;
  }
  if (v.startsWith('mailto:')) {
    return ScanType.email;
  }
  return ScanType.text;
}
