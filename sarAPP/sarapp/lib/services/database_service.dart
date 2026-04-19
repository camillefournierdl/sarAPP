import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_module.dart';
import '../models/app_settings.dart';
import '../models/custom_module.dart';
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
            weather_score    INTEGER,
            work_day         TEXT,
            foods            TEXT    NOT NULL DEFAULT '[]',
            activities       TEXT    NOT NULL DEFAULT '[]',
            health_status    TEXT,
            sick_tags        TEXT    NOT NULL DEFAULT '[]',
            notes            TEXT    NOT NULL DEFAULT '',
            libido_score     INTEGER,
            had_sex          TEXT,
            water_glasses    INTEGER,
            custom_data      TEXT    NOT NULL DEFAULT '{}',
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
        // v3 → v4: add weather_score column
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN weather_score INTEGER');
        }
        // v4 → v5: add work_day column
        if (oldVersion < 5) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN work_day TEXT');
        }
        // v5 → v6: add health_status and sick_tags columns
        if (oldVersion < 6) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN health_status TEXT');
          await db.execute(
              "ALTER TABLE entries ADD COLUMN sick_tags TEXT NOT NULL DEFAULT '[]'");
        }
        // v6 → v7: split activities into sports + leisure
        if (oldVersion < 7) {
          await db.execute(
              "ALTER TABLE entries ADD COLUMN sports TEXT NOT NULL DEFAULT '[]'");
          await db.execute(
              "UPDATE entries SET sports = activities");
          await db.execute(
              "ALTER TABLE entries ADD COLUMN leisure TEXT NOT NULL DEFAULT '[]'");
        }
        // v7 → v8: add custom_data column for user-defined module responses
        if (oldVersion < 8) {
          await db.execute(
              "ALTER TABLE entries ADD COLUMN custom_data TEXT NOT NULL DEFAULT '{}'");
        }
        // v8 → v9: add libido_score, had_sex, water_glasses columns
        if (oldVersion < 9) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN libido_score INTEGER');
          await db.execute(
              'ALTER TABLE entries ADD COLUMN had_sex TEXT');
          await db.execute(
              'ALTER TABLE entries ADD COLUMN water_glasses INTEGER');
        }
      },
      version: 9,
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
  /// Migrates the old 'activity' key to 'sports' + 'leisure'.
  static Set<String> _parseModules(String? raw) {
    if (raw == null) return AppModule.defaultEnabled;
    try {
      final modules = Set<String>.from(jsonDecode(raw) as List);
      if (modules.remove('activity')) {
        modules.addAll(['sports', 'leisure']);
      }
      return modules;
    } catch (_) {
      return AppModule.defaultEnabled;
    }
  }

  static List<CustomModule> _parseCustomModules(String? raw) {
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => CustomModule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, String> _parseQuestionOverrides(String? raw) {
    if (raw == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  static List<String> _parseModuleOrder(String? raw) {
    const defaultOrder = [
      'happiness', 'emotions', 'sleep', 'weather',
      'health', 'work', 'sports', 'leisure', 'food', 'symptoms', 'notes',
    ];
    if (raw == null) return defaultOrder;
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return defaultOrder;
    }
  }

  static List<String> _parseStringList(String? raw, List<String> fallback) {
    if (raw == null) return fallback;
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return fallback;
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
      menstruationTracking:
          (await _getSetting('menstruation_tracking') ?? 'true') == 'true',
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
      calendarStartDay: await _getSetting('calendar_start_day'),
      showHighFertility:
          (await _getSetting('show_high_fertility') ?? 'false') == 'true',
      customEmotions: _parseStringList(
          await _getSetting('custom_emotions'),
          const ['😊 Happy', '😢 Sad', '😤 Angry', '😰 Anxious', '😴 Tired', '⚡ Energized']),
      customSymptoms: _parseStringList(
          await _getSetting('custom_symptoms'),
          const ['cramps', 'bloating', 'headache', 'fatigue', 'mood swings', 'breast tenderness', 'back pain', 'acne']),
      customSports: _parseStringList(
          await _getSetting('custom_sports'),
          const ['🏋️ Weight lifting', '🏃 Intense cardio', '🚴 Endurance', '💃 Dance', '🧗 Climbing']),
      customLeisure: _parseStringList(
          await _getSetting('custom_leisure'),
          const ['📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming']),
      customFoods: _parseStringList(
          await _getSetting('custom_foods'),
          const ['🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish']),
      customSickTags: _parseStringList(
          await _getSetting('custom_sick_tags'),
          const ['🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '🔥 Fever', '🫄 Digestive issues', '😮‍💨 Fatigue']),
      customModules: _parseCustomModules(await _getSetting('custom_modules')),
      customModuleQuestions: _parseQuestionOverrides(
          await _getSetting('custom_module_questions')),
      moduleOrder: _parseModuleOrder(await _getSetting('module_order')),
    );
  }

  static Future<void> saveSettings(AppSettings s) async {
    await _saveSetting('menstruation_tracking', s.menstruationTracking.toString());
    await _saveSetting('notification_hour', s.notificationHour.toString());
    await _saveSetting('notification_minute', s.notificationMinute.toString());
    await _saveSetting(
        'notifications_enabled', s.notificationsEnabled.toString());
    await _saveSetting('onboarding_complete', s.onboardingComplete.toString());
    await _saveSetting('enabled_modules', jsonEncode(s.enabledModules.toList()));
    await _saveSetting('show_high_fertility', s.showHighFertility.toString());
    await _saveSetting('custom_emotions', jsonEncode(s.customEmotions));
    await _saveSetting('custom_symptoms', jsonEncode(s.customSymptoms));
    await _saveSetting('custom_sports', jsonEncode(s.customSports));
    await _saveSetting('custom_leisure', jsonEncode(s.customLeisure));
    await _saveSetting('custom_foods', jsonEncode(s.customFoods));
    await _saveSetting('custom_sick_tags', jsonEncode(s.customSickTags));
    await _saveSetting('custom_modules',
        jsonEncode(s.customModules.map((m) => m.toJson()).toList()));
    await _saveSetting('custom_module_questions',
        jsonEncode(s.customModuleQuestions));
    await _saveSetting('module_order', jsonEncode(s.moduleOrder));
    if (s.calendarStartDay != null) {
      await _saveSetting('calendar_start_day', s.calendarStartDay!);
    } else {
      await _deleteSetting('calendar_start_day');
    }
    if (s.lastPeriodStart != null) {
      await _saveSetting('last_period_start', s.lastPeriodStart!);
    } else {
      await _deleteSetting('last_period_start');
    }
  }
}
