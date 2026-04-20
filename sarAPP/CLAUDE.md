# sarAPP — Project Guide

Flutter daily-journaling app. All data stays on-device (SQLite via sqflite). No accounts, no cloud.

## Repo layout

```
sarAPP/
├── sarapp/lib/
│   ├── main.dart                   Entry point, providers, theme
│   ├── models/
│   │   ├── app_module.dart         Built-in module definitions (key, label, emoji, responseType, defaultOptions, labelLow/High)
│   │   ├── custom_module.dart      User-created module data class (id, name, question, responseType, options, labelLow/High, conditional*)
│   │   ├── app_settings.dart       All user settings; convenience accessors optionsFor/labelLowFor/labelHighFor
│   │   ├── entry.dart              One day's logged data
│   │   └── app_module.dart         (see above)
│   ├── providers/
│   │   ├── settings_provider.dart  ChangeNotifier wrapping AppSettings; load/update/save
│   │   └── entries_provider.dart   ChangeNotifier wrapping List<Entry>
│   ├── services/
│   │   ├── database_service.dart   SQLite CRUD for entries + settings key-value store
│   │   ├── cycle_service.dart      Cycle length / phase calculations
│   │   ├── export_service.dart     CSV export
│   │   └── notification_service.dart  Daily reminder scheduling
│   ├── screens/
│   │   ├── home_screen.dart        Bottom nav shell
│   │   ├── log_entry_screen.dart   Daily questionnaire (paginated, 3 modules/page)
│   │   ├── calendar_screen.dart    Monthly calendar with cycle/entry overlay
│   │   ├── history_screen.dart     Past entries list
│   │   ├── charts_screen.dart      Data visualisations
│   │   ├── settings_screen.dart    All settings + module edit screens
│   │   └── onboarding_screen.dart  First-launch flow
│   └── widgets/
│       ├── emotion_tag_selector.dart   Chip selector with built-in color mapping
│       ├── symptom_selector.dart       Multi-select chip selector
│       └── cycle_phase_selector.dart
└── sarapp/pubspec.yaml
```

## Module architecture

### Built-in modules (`AppModule`)
- Defined as `static const` in `app_module.dart`
- Keys: `happiness`, `emotions`, `sleep`, `weather`, `health`, `work`, `sports`, `leisure`, `food`, `symptoms`, `libido`, `sex`, `water`, `notes`
- Each carries: `responseType` (ResponseType enum), `defaultOptions` (List<String>), `labelLow`/`labelHigh` (String, empty = no label)
- `work` and `sex` use specialized rendering widgets in log_entry_screen; their options are NOT list-driven

### Custom modules (`CustomModule`)
- User-created, stored as JSON in the settings table
- Same fields as built-ins plus: `id` (UUID), `name`, `emoji`, `question`, optional `conditionalTrigger`/`conditionalQuestion`/`conditionalOptions`

### AppSettings — unified option storage
- `Map<String, List<String>> moduleOptions` — keyed by module key for built-ins
- `Map<String, String> moduleLabelLow / moduleLabelHigh` — user overrides for slider end labels
- Accessors: `optionsFor(key)`, `labelLowFor(key)`, `labelHighFor(key)` — fall back to AppModule defaults
- `Map<String, String> customModuleQuestions` — overrides the question text for built-in modules

### ResponseType enum (in custom_module.dart)
`scale | multiSelect | singleSelect | text | conditional`

## Database (SQLite)

- **`entries` table** — one row per date, columns per field
- **`settings` table** — key/value store for all AppSettings
  - `module_options` — JSON `Map<String, List<String>>` (replaces old `custom_emotions` etc.)
  - `module_label_low` / `module_label_high` — JSON `Map<String, String>`
  - `custom_modules` — JSON array of CustomModule objects
  - `custom_module_questions` — JSON `Map<String, String>`
  - `module_order` — JSON list of keys/ids
  - Migration: on first load after upgrade, if `module_options` is absent, old `custom_emotions`/`custom_sports`/etc. keys are merged into it and the old keys are left in place (harmless)

## Key screens

### `log_entry_screen.dart`
- `_buildBuiltinModule()` — switch on module key, uses `settings.optionsFor(key)` and `settings.labelLowFor/labelHighFor(key)`
- `_buildCustomModuleInput()` — generic renderer for all ResponseTypes; passes `m.labelLow/labelHigh` to `_HappinessSlider`
- `_HappinessSlider` — `labelLow`/`labelHigh` default `''`; rendered only when non-empty

### `settings_screen.dart`
- `ModulesScreen` — reorderable list, toggle enable/disable, tap ✏️ to edit
- `CustomizeModulesScreen` — flat list of all modules linking to edit screen
- `ModuleEditScreen` — unified edit screen for both built-ins and custom modules
  - Built-ins: response type shown as read-only chip; name/emoji hidden
  - Custom: all fields editable
  - Scale modules: shows Low label / High label text fields
  - Multi-select: shows editable options list with `e.g. 😊 Happy` hint

## Settings screen section order
Questionnaire modules → Tracking → Cycle (only if menstruation tracking on) → Reminder → Data → About

## Conventions
- Options are plain strings; emoji is embedded directly (e.g. `'😊 Happy'`)
- `copyWith` uses a `_sentinel` object to distinguish null from "not provided" for nullable fields
- Never run `flutter analyze` / `flutter build` proactively — user runs those
