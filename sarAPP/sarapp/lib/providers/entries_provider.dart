import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../services/database_service.dart';

class EntriesProvider extends ChangeNotifier {
  List<Entry> _entries = [];

  List<Entry> get entries => _entries;

  Future<void> load() async {
    _entries = await DatabaseService.getAllEntries();
    notifyListeners();
  }

  Future<void> saveEntry(Entry entry) async {
    await DatabaseService.upsertEntry(entry);
    await load(); // refresh the list
  }

  Future<void> deleteEntry(int id) async {
    await DatabaseService.deleteEntry(id);
    await load();
  }

  Future<void> clearAll() async {
    await DatabaseService.clearAllEntries();
    _entries = [];
    notifyListeners();
  }

  /// Returns today's entry, or null if none logged yet.
  Entry? getByDate(String date) {
    try {
      return _entries.firstWhere((e) => e.date == date);
    } catch (_) {
      return null;
    }
  }
}
