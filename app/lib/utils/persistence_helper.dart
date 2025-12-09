import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PersistenceHelper {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/alerted_visitors_v3.json');
  }

  static Future<List<String>> loadAlertedIds() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.cast<String>();
    } catch (e) {
      debugPrint('Error loading alerted IDs: $e');
      return [];
    }
  }

  static Future<void> saveAlertedId(String id) async {
    try {
      final ids = await loadAlertedIds();
      if (!ids.contains(id)) {
        ids.add(id);
        final file = await _getFile();
        await file.writeAsString(jsonEncode(ids));
        debugPrint('✅ Persisted Visitor ID: $id');
      }
    } catch (e) {
      debugPrint('❌ Error saving alerted ID: $e');
    }
  }
}
