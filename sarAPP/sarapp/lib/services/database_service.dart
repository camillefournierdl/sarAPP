import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_module.dart';
import '../models/app_settings.dart';
import '../models/entry.dart';

class DatabaseService {
  static Database? _db;

  // Lazily initialise — only opens the DB the first time it's needed
  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'sarapp.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entries (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            date             TEXT    UNIQUE NOT NULL,
            emotions         TEXT    NOT NULL DEFAULT '[]',
            cycle_phase      TEXT,
            period_start     INTEGER NOT NULL DEFAULT 0,
            period_end       INTEGER NOT NULL DEFAULT 0,
            symptoms         TEXT    NOT NULL DEFAULT '[]',
            happiness_score  INTEGER,
            sleep_score      INTEGER,
            foods            TEXT    NOT NULL DEFAULT '[]',
            activities       TEXT    NOT NULL DEFAULT '[]',
            notes            TEXT    NOT NULL DEFAULT '',
            created_at       TEXT    NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key   TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: add happiness_score, foods, activities columns
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN happiness_score INTEGER');
          await db.execute(
              "ALTER TABLE entries ADD COLUMN foods TEXT NOT NULL DEFAULT '[]'");
          await db.execute(
              "ALTER TABLE entries ADD COLUMN activities TEXT NOT NULL DEFAULT '[]'");
        }
        // v2 → v3: add sleep_score column
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN sleep_score INTEGER');
        }
      },
      version: 3,
    );
  }

  // ── Entries ────────────────────────────────────────────────────────────────

  /// Insert or replace an entry for a given date.
  static Future<void> upsertEntry(Entry entry) async {
    final db = await database;
    final map = entry.toMap();
    map.remove('id'); // let SQLite assign the id on insert; REPLACE handles updates
    await db.insert('entries', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Entry>> getAllEntries() async {
    final db = await database;
    final rows = await db.query('entries', orderBy: 'date DESC');
    return rows.map(Entry.fromMap).toList();
  }

  static Future<Entry?> getEntryByDate(String date) async {
    final db = await database;
    final rows =
        await db.query('entries', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? null : Entry.fromMap(rows.first);
  }

  static Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAllEntries() async {
    final db = await database;
    await db.delete('entries');
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static Future<void> _saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> _deleteSetting(String key) async {
    final db = await database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }

  /// Parses a JSON-encoded list of module keys, falling back to defaults.
  static Set<String> _parseModules(String? raw) {
    if (raw == null) return AppModule.defaultEnabled;
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return AppModule.defaultEnabled;
    }
  }

  static Future<String?> _getSetting(String key) async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<AppSettings> loadSettings() async {
    return AppSettings(
      userMode: await _getSetting('user_mode') ?? 'female',
      notificationHour:
          int.tryParse(await _getSetting('notification_hour') ?? '20') ?? 20,
      notificationMinute:
          int.tryParse(await _getSetting('notification_minute') ?? '0') ?? 0,
      notificationsEnabled:
          (await _getSetting('notifications_enabled')) == 'true',
      onboardingComplete:
          (await _getSetting('onboarding_complete')) == 'true',
      lastPeriodStart: await _getSetting('last_period_start'),
      enabledModules: _parseModules(await _getSetting('enabled_modules')),
    );
  }

  static Future<void> saveSettings(AppSettings s) async {
    await _saveSetting('user_mode', s.userMode);
    await _saveSetting('notification_hour', s.notificationHour.toString());
    await _saveSetting('notification_minute', s.notificationMinute.toString());
    await _saveSetting(
        'notifications_enabled', s.notificationsEnabled.toString());
    await _saveSetting('onboarding_complete', s.onboardingComplete.toString());
    await _saveSetting('enabled_modules', jsonEncode(s.enabledModules.toList()));
    if (s.lastPeriodStart != null) {
      await _saveSetting('last_period_start', s.lastPeriodStart!);
    } else {
      await _deleteSetting('last_period_start');
    }
  }
}
