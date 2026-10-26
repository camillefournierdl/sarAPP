import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_settings.dart';
import '../models/entry.dart';

class BackupData {
  final List<Entry> entries;
  final AppSettings settings;
  const BackupData({required this.entries, required this.settings});
}

class BackupService {
  static const _backupVersion = 1;

  static Future<void> exportToJson(
      List<Entry> entries, AppSettings settings) async {
    final backup = {
      'app': 'sarapp',
      'backupVersion': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sarapp_backup.json');
    await file.writeAsString(jsonEncode(backup));

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'sarapp Data Backup',
    );
  }

  /// Throws [FormatException] if [jsonString] isn't a sarapp backup.
  static BackupData parseBackup(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic> || decoded['app'] != 'sarapp') {
      throw const FormatException('This file is not a valid sarapp backup.');
    }
    final entries = (decoded['entries'] as List? ?? const [])
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList();
    final settings = decoded['settings'] != null
        ? AppSettings.fromJson(decoded['settings'] as Map<String, dynamic>)
        : const AppSettings();
    return BackupData(entries: entries, settings: settings);
  }
}
