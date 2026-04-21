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
            stress_score     INTEGER,
            weather_score    INTEGER,
            work_day         TEXT,
            foods            TEXT    NOT NULL DEFAULT '[]',
            activities       TEXT    NOT NULL DEFAULT '[]',
            sports           TEXT    NOT NULL DEFAULT '[]',
            leisure          TEXT    NOT NULL DEFAULT '[]',
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
        // v9 → v10: fix fresh-install schema that was missing sports/leisure
        if (oldVersion < 10) {
          final cols = await db.rawQuery('PRAGMA table_info(entries)');
          final existing = cols.map((c) => c['name'] as String).toSet();
          if (!existing.contains('sports')) {
            await db.execute(
                "ALTER TABLE entries ADD COLUMN sports TEXT NOT NULL DEFAULT '[]'");
          }
          if (!existing.contains('leisure')) {
            await db.execute(
                "ALTER TABLE entries ADD COLUMN leisure TEXT NOT NULL DEFAULT '[]'");
          }
        }
        // v10 → v11: add stress_score column
        if (oldVersion < 11) {
          await db.execute(
              'ALTER TABLE entries ADD COLUMN stress_score INTEGER');
        }
      },
      version: 11,
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
      'happiness', 'emotions', 'sleep', 'stress', 'weather',
      'health', 'work', 'sports', 'leisure', 'food', 'water',
      'symptoms', 'libido', 'sex', 'notes',
    ];
    if (raw == null) return defaultOrder;
    try {
      final saved = List<String>.from(jsonDecode(raw) as List);
      // Append any known builtin keys that are missing from a saved order
      // (handles upgrades where new modules were added after initial install).
      for (final key in defaultOrder) {
        if (!saved.contains(key)) saved.add(key);
      }
      return saved;
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

  static Map<String, List<String>> _parseModuleOptions(String? raw) {
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
    } catch (_) {
      return const {};
    }
  }

  static Map<String, String> _parseStringMap(String? raw) {
    if (raw == null) return const {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  static bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Future<String?> _getSetting(String key) async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  static Future<AppSettings> loadSettings() async {
    // Migration: if module_options key absent, build it from old named keys (runs once).
    final rawModuleOptions = await _getSetting('module_options');
    Map<String, List<String>> moduleOptions;
    if (rawModuleOptions != null) {
      moduleOptions = _parseModuleOptions(rawModuleOptions);
    } else {
      moduleOptions = {
        'emotions': _parseStringList(await _getSetting('custom_emotions'),   AppModule.emotions.defaultOptions),
        'symptoms': _parseStringList(await _getSetting('custom_symptoms'),   AppModule.symptoms.defaultOptions),
        'sports':   _parseStringList(await _getSetting('custom_sports'),     AppModule.sports.defaultOptions),
        'leisure':  _parseStringList(await _getSetting('custom_leisure'),    AppModule.leisure.defaultOptions),
        'food':     _parseStringList(await _getSetting('custom_foods'),      AppModule.food.defaultOptions),
        // 'health' intentionally excluded: sick tags move to module_conditional_options
      };
      await _saveSetting('module_options', jsonEncode(
          moduleOptions.map((k, v) => MapEntry(k, v))));
    }

    // Migration: if module_conditional_options absent, migrate health sick tags from
    // module_options (old format stored them there) or old custom_sick_tags key.
    final rawCondOptions = await _getSetting('module_conditional_options');
    Map<String, List<String>> moduleConditionalOptions;
    if (rawCondOptions != null) {
      moduleConditionalOptions = _parseModuleOptions(rawCondOptions);
    } else {
      moduleConditionalOptions = {};
      if (moduleOptions.containsKey('health')) {
        // Old data: health entry in moduleOptions = sick tags → move to conditional
        moduleConditionalOptions['health'] = moduleOptions['health']!;
        moduleOptions = Map.from(moduleOptions)..remove('health');
        await _saveSetting('module_options', jsonEncode(moduleOptions));
      } else {
        // No customized sick tags; fall back to default via raw key
        final oldSickTags = await _getSetting('custom_sick_tags');
        if (oldSickTags != null) {
          moduleConditionalOptions['health'] =
              _parseStringList(oldSickTags, AppModule.health.conditionalDefaultOptions);
        }
      }
      await _saveSetting('module_conditional_options', jsonEncode(moduleConditionalOptions));
    }

    // Migration: infer user_modified_module_options on first load by comparing
    // stored options to current AppModule defaults. Stored options that differ
    // from defaults are assumed to be user customizations.
    final rawUserModified = await _getSetting('user_modified_module_options');
    Set<String> userModifiedModuleOptions;
    if (rawUserModified != null) {
      userModifiedModuleOptions = Set<String>.from(
          jsonDecode(rawUserModified) as List);
    } else {
      userModifiedModuleOptions = {};
      for (final module in AppModule.all) {
        final stored = moduleOptions[module.key];
        if (stored != null &&
            !_listsEqual(stored, module.defaultOptions)) {
          userModifiedModuleOptions.add(module.key);
        }
      }
      await _saveSetting('user_modified_module_options',
          jsonEncode(userModifiedModuleOptions.toList()));
    }

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
      showLastSex:
          (await _getSetting('show_last_sex') ?? 'false') == 'true',
      moduleOptions: moduleOptions,
      userModifiedModuleOptions: userModifiedModuleOptions,
      moduleLabelLow: _parseStringMap(await _getSetting('module_label_low')),
      moduleLabelHigh: _parseStringMap(await _getSetting('module_label_high')),
      moduleConditionalOptions: moduleConditionalOptions,
      moduleConditionalTrigger: _parseStringMap(await _getSetting('module_conditional_trigger')),
      moduleConditionalQuestion: _parseStringMap(await _getSetting('module_conditional_question')),
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
    await _saveSetting('show_last_sex', s.showLastSex.toString());
    await _saveSetting('module_options',
        jsonEncode(s.moduleOptions.map((k, v) => MapEntry(k, v))));
    await _saveSetting('user_modified_module_options',
        jsonEncode(s.userModifiedModuleOptions.toList()));
    await _saveSetting('module_label_low', jsonEncode(s.moduleLabelLow));
    await _saveSetting('module_label_high', jsonEncode(s.moduleLabelHigh));
    await _saveSetting('module_conditional_options',
        jsonEncode(s.moduleConditionalOptions.map((k, v) => MapEntry(k, v))));
    await _saveSetting('module_conditional_trigger', jsonEncode(s.moduleConditionalTrigger));
    await _saveSetting('module_conditional_question', jsonEncode(s.moduleConditionalQuestion));
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
