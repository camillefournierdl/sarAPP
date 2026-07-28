# Analytics Tab — Implementation Plan

## Overview

Add an Analytics tab to the app that lets users pick a focus module and see
what other tracked variables are associated with it. Associations are computed
using standard non-parametric statistics and presented in plain language.
A "Nerd mode" setting exposes the statistical details.

---

## Confirmed assumptions

- `AppSettings.enabledModules` is a `Set<String>` with `isModuleEnabled(key)`.
  The analytics module picker and predictor enumeration both use this.
- `stress`, `libido`, `sex`, `water`, `symptoms` are opt-in (not in the default
  enabled set). Analytics respects `enabledModules` — these are only shown if
  the user has turned them on.
- `Entry.workDay` stores `'off'|'half'|'full'` (lowercase, no emoji), but
  `AppModule.work.defaultOptions` are `'🌿 Day off'` etc. Extraction must use
  a hardcoded mapping for this built-in field.
- `Entry.healthStatus` stores `'sick'|'healthy'` (lowercase), but
  `AppModule.health.conditionalTrigger` is `'Sick'` (capitalized). Extraction
  uses `.toLowerCase()` comparison.
- `Entry.hadSex` stores `'yes'|'no'`. `AppModule.sex.defaultOptions` are
  `'Yes'|'No'`. Use `.toLowerCase()` comparison.
- Follow-up options for the `health` conditional are in
  `AppSettings.moduleConditionalOptions['health']`, not hardcoded.
- The submit flow in `log_entry_screen.dart` must be read before implementing
  `answeredModules` population (Step 0).

---

## What is NOT included in v1

| Omission | Reason |
|----------|--------|
| `compute()` isolate | ≤365 entries × ~30 pairs runs in milliseconds. Add only if profiling shows jank. |
| Phi coefficient (event × event) | Rare co-occurrence of two specific tags. Low value, adds complexity. Add later. |
| "Show more" button | Speculative. Add if the list is actually overwhelming in practice. |
| Focus persistence across restarts | Session-scoped state is sufficient for v1. |

---

## ResponseType handling

### As a focus module

| ResponseType | Focus behaviour | Framing |
|---|---|---|
| `scale` | One-step pick. High group = top third of logged values; low group = bottom third; middle excluded. | "What is associated with [labelHighFor(key) or label]?" |
| `multiSelect` | Two-step: pick module → pick specific tag from `optionsFor(key)`. Event focus (tag present / absent). | "What is associated with days you logged [tag]?" |
| `singleSelect` | Two-step: pick module → pick specific value from `optionsFor(key)`. Event focus. | "What is associated with days you logged [value]?" |
| `conditional` | Two-step: pick module → pick either the trigger value (e.g. "Sick") OR a follow-up tag. Each is a separate event focus. | "What is associated with days you logged [value/tag]?" |
| `text` | **Excluded from picker.** |  |

### As a predictor

| ResponseType | Extraction | Test vs scale focus | Test vs event focus |
|---|---|---|---|
| `scale` | `_scaleValue(entry, key)` → `double?` | Spearman ρ | Mann-Whitney U |
| `multiSelect` | Each option = separate predictor. `tag in list` → `bool?` (null if not answered, see Step 0). | Mann-Whitney U | *(skipped in v1)* |
| `singleSelect` | Each option = separate predictor. `storedValue == option` → `bool?`. | Mann-Whitney U | *(skipped in v1)* |
| `conditional` | Primary: `storedValue == trigger` → `bool?`. Follow-up: each tag → `bool?`. | Mann-Whitney U | *(skipped in v1)* |
| `text` | **Excluded as predictor.** | | |

### Statistical test selection matrix

| Focus type | Predictor type | Test used |
|---|---|---|
| Scale | Scale | Spearman ρ |
| Scale | Event (any) | Mann-Whitney U |
| Event | Scale | Mann-Whitney U |
| Event | Event | *(skipped in v1)* |

---

## Module display names

`AssociationResult` stores raw keys/ids only. The widget resolves names:
- Built-in: `AppModule.forKey(key)?.label` → e.g. `"Stress"`
- Custom: `settings.customModules.firstWhere((m) => m.id == key).name`

Scale focus framing uses:
- `settings.labelHighFor(key)` if non-empty → e.g. `"😤"` (used as-is or alongside label)
- Otherwise falls back to `AppModule.forKey(key)?.label` → e.g. `"Stress"`

---

## Implementation steps

### Step 0 — Add `answeredModules` to `Entry`

**Files:** `models/entry.dart`, `services/database_service.dart`,
`screens/log_entry_screen.dart`

**Read `log_entry_screen.dart` before implementing this step.**

Add to `Entry`:
```dart
final Set<String> answeredModules; // module keys the user submitted
```
Default: `const {}` (old entries are safe — analytics falls back gracefully).

In `database_service.dart`: bump DB version, add `answered_modules` column
(JSON array). Old rows read as empty set.

In `log_entry_screen.dart`: populate `answeredModules` with every module key
the user interacted with when building the `Entry` to save.

**Analytics fallback for old entries (empty `answeredModules`):**
- Scale modules: `null` field value already means "not answered" — no change.
- List-based modules (multiSelect, conditional follow-ups): treat non-empty list
  as "answered". Empty list on an old entry = treat as null (exclude from paired
  observations). This is conservative and correct.

**Verify:** Save an entry, read it back, confirm `answeredModules` contains the
expected keys. Old entries load without error.

---

### Step 1 — Add `analyticsNerdMode` to `AppSettings`

**Files:** `models/app_settings.dart`, `services/database_service.dart`

Add `final bool analyticsNerdMode` (default `false`) to `AppSettings` and
its `copyWith`. In `database_service.dart`, load/save under key
`analytics_nerd_mode`. No DB migration needed — absent key falls back to
`false`.

**Verify:** Toggle the setting, restart, confirm it persists.

---

### Step 2 — `AnalyticsService`

**New file:** `services/analytics_service.dart`

Pure Dart, no imports beyond `dart:math`. All methods are static.

#### Data types

```dart
class AnalyticsFocus {
  final String moduleKey;  // built-in key or custom id
  final String? tag;       // null = scale focus; string = event focus
  const AnalyticsFocus({required this.moduleKey, this.tag});
}

enum AssociationLag { sameDay, previousDay }

class AssociationResult {
  final String predictorKey;          // module key or custom id
  final String? predictorTag;         // null if predictor is scale
  final AssociationLag lag;
  final double effectSize;            // always positive (|r| or |phi|)
  final double pValue;
  final int n;                        // paired observations used
  final String testName;              // "Spearman ρ" or "Mann-Whitney U"
  final bool isLimitedData;           // n < 30
  final double focusGroupValue;       // mean or rate for the focus group
  final double comparisonGroupValue;  // mean or rate for the comparison group
}
```

#### Statistics helpers (private static)

**`_normalCdf(double z)`** — Abramowitz & Stegun 26.2.17 rational approximation,
error < 7.5×10⁻⁸. ~12 lines. Used by both tests.

**`_spearman(List<double> x, List<double> y)`** → `({double r, double p, int n})`
1. Rank both lists with average ranks for ties.
2. `r` = Pearson correlation on the rank vectors.
3. `t = r * sqrt((n-2) / (1 - r²))`. Guard: if `r.abs() == 1.0`, return `p = 0.0`.
4. `p = 2 * (1 - _normalCdf(t.abs()))` (normal approximation, valid for n > 15).

**`_mannWhitney(List<double> eventDays, List<double> nonEventDays)`**
→ `({double r, double p, int n})`
1. Compute U statistic by counting concordant pairs.
2. Normal approximation with tie correction:
   `z = (U - n1*n2/2) / sqrt(n1*n2*(n1+n2+1)/12)`.
3. Effect: rank-biserial `r = 1 - 2U / (n1 * n2)`.
4. `p = 2 * (1 - _normalCdf(z.abs()))`.

#### Extraction helpers (private static)

**`_scaleValue(Entry e, String key)`** → `double?`
Switch on built-in key → cast relevant `int?` field to double.
Custom modules: `e.customData[key] as int?`.

**`_eventPresence(Entry e, String moduleKey, String tag, {required bool isBuiltin})`**
→ `bool?`

Built-in modules:
- `emotions`, `sports`, `leisure`, `food`, `symptoms`: if `moduleKey` not in
  `e.answeredModules` AND `e.answeredModules` is non-empty → return `null`.
  Otherwise return `tag in list`.
- `work`: map display option to stored value
  (`'🌿 Day off'→'off'`, `'🌗 Half day'→'half'`, `'💼 Full day'→'full'`),
  return `e.workDay?.toLowerCase() == mappedValue`.
- `sex`: return `e.hadSex?.toLowerCase() == tag.toLowerCase()`.
- `health` primary: return `e.healthStatus?.toLowerCase() ==
  AppModule.health.conditionalTrigger.toLowerCase()`.
- `health` follow-up tags: if moduleKey not in `answeredModules` AND
  `answeredModules` non-empty → null. Otherwise return `tag in e.sickTags`.
- `menstruation` (periodStart/periodEnd): handle if included as a module.

Custom modules: read from `e.customData[moduleKey]`, type-check safely:
- `scale`: `(e.customData[moduleKey] as int?) != null` → not applicable here
- `multiSelect/singleSelect`: `e.customData[moduleKey] as List?` → check tag
- `conditional`: check trigger and follow-up separately

#### Main method

```dart
static List<AssociationResult> computeAssociations({
  required List<Entry> entries,
  required AnalyticsFocus focus,
  required AppSettings settings,
  DateTime? windowStart,
  DateTime? windowEnd,
})
```

1. Filter entries to window, sort by date ascending.
2. Build `Map<String, Entry>` keyed by `'YYYY-MM-DD'` for O(1) lag-1 lookup.
   Lag-1 = calendar day minus 1; if no entry exists for that date, skip the
   paired observation (no imputation).
3. Determine focus type: look up `ResponseType` from `AppModule.forKey(key)`
   or `settings.customModules`.
4. Enumerate all predictor modules from `settings.enabledModules` +
   `settings.customModules` (enabled), excluding the focus module itself and
   `text` type modules.
5. For each predictor × lag {sameDay, previousDay}:
   a. Collect paired observations, skipping nulls from either side.
   b. Skip if `n < 15`.
   c. Choose test per the matrix above.
   d. Run test; skip if `effectSize < 0.20`.
   e. Skip if `p >= 0.05`, or `p >= 0.10` when `n < 30`.
   f. Build `AssociationResult` with `isLimitedData = n < 30`.
6. Sort by `effectSize` descending, return all passing results.

**Verify:** Unit test with 30 hand-crafted entries where stress is always high
on migraine days. Confirm a result appears with large effect size and low p.
Test with 10 entries — confirm empty result list with `n < 15` guard.

---

### Step 3 — `AnalyticsProvider`

**New file:** `providers/analytics_provider.dart`

```dart
class AnalyticsProvider extends ChangeNotifier {
  AnalyticsFocus? focus;
  AnalyticsTimeWindow timeWindow = AnalyticsTimeWindow.allTime;
  DateTimeRange? customRange;
  List<AssociationResult> results = [];
  bool isComputing = false;
  int entryCount = 0;  // for the transparency footer

  Future<void> setFocus(AnalyticsFocus f, List<Entry> entries, AppSettings s);
  Future<void> setTimeWindow(AnalyticsTimeWindow w, List<Entry> entries,
      AppSettings s, {DateTimeRange? range});
  Future<void> _recompute(List<Entry> entries, AppSettings s);
}

enum AnalyticsTimeWindow { allTime, lastMonth, last3Months, custom }
```

`_recompute` calls `AnalyticsService.computeAssociations` inside a
`Future.microtask` — no isolate needed.

**Verify:** Set focus, confirm `results` populates and `isComputing` transitions
correctly.

---

### Step 4 — Register provider in `main.dart`

Add `ChangeNotifierProvider(create: (_) => AnalyticsProvider())` to
`MultiProvider`.

---

### Step 5 — `AnalyticsScreen`

**New file:** `screens/analytics_screen.dart`

#### Widget tree

```
AnalyticsScreen
  └── Consumer2<AnalyticsProvider, SettingsProvider>
      ├── _TimeWindowBar
      │     SegmentedButton: All time / Last month / 3 months / Custom
      │     Custom → showDateRangePicker
      ├── _FocusModulePicker  (StatefulWidget)
      │     Step 0: list of enabled non-text modules
      │     Step 1 (event modules only): tag chip picker
      │     Back affordance between steps
      ├── focus == null         → _EmptyState
      ├── isComputing           → CircularProgressIndicator
      ├── entryCount < 15       → "Not enough data yet — keep logging!"
      ├── results empty         → "No significant associations found in this period"
      └── ListView
            ├── _AssociationCard × N
            └── _TransparencyFooter
```

#### `_FocusModulePicker`

Stateful. Internal state: `_step` (0 or 1) and `_pendingKey`.
- Scale module tapped → call `analyticsProvider.setFocus(...)` immediately.
- Event module tapped → advance to step 1 showing tag chips.
- Tag tapped → call `analyticsProvider.setFocus(...)`.

Module list built from `settings.enabledModules` (ordered by `settings.moduleOrder`),
filtering out `text` type. Resolve display name and emoji per the "Module display
names" section above.

For `conditional` modules: step 1 shows the trigger value (e.g. "Sick") AND all
follow-up options (from `settings.conditionalOptionsFor(key)`) as selectable chips.

#### `_AssociationCard`

Builds natural language from `AssociationResult` fields in the widget.

Templates:
- Scale focus, scale predictor:
  `"[Predictor label] tends to be [higher/lower] on [labelHigh] days (avg [focusGroupValue] vs [comparisonGroupValue])"`
  + lag label: `"· same day"` or `"· previous day"`
- Scale focus, event predictor:
  `"[labelHigh] days more often follow [tag] days ([focusGroupValue*100]% vs [comparisonGroupValue*100]%)"`
- Event focus, scale predictor:
  `"[Predictor label] was [higher/lower] on [tag] days (avg [focusGroupValue] vs [comparisonGroupValue])"`

Nerd mode (`settings.analyticsNerdMode == true`) adds a second line:
`"[testName] = [effectSize, 2dp] · p = [pValue, 3dp] · n = [n]"`

When `isLimitedData`: add a note below the card:
`"Based on limited data — treat with caution"`

#### `_TransparencyFooter`

```
"Based on [entryCount] entries · [window label] · Indicative only"
```

**Verify:** Three render states work (empty, not enough data, results). A card
in nerd mode shows the correct test name, effect size, p-value, and n.

---

### Step 6 — Nerd mode toggle in `SettingsScreen`

**File:** `screens/settings_screen.dart`

Add an `'Analytics'` section after the existing `'Tracking'` section.
One `SwitchListTile` with `Icons.science_outlined`, title `'Nerd mode'`,
subtitle `'Show statistical details on association cards'`.

Surgical change — nothing else in the file touched.

**Verify:** Toggle persists across app restart.

---

### Step 7 — New tab in `HomeScreen`

**File:** `screens/home_screen.dart`

Insert `AnalyticsScreen` at index 3; `SettingsScreen` moves to index 4.
Add `NavigationDestination(icon: Icon(Icons.insights), label: 'Analytics')`.

Note: if `_tab` state is preserved across hot reloads during development, a
range error can occur. Clamp `_tab` to `[0, _tabs.length - 1]` in the
state initialisation to guard against this.

**Verify:** Tab navigates correctly. Hot reload does not cause a range error.

---

## Implementation order

```
Step 0  Entry.answeredModules           verify: save/load roundtrip
Step 1  AppSettings.analyticsNerdMode  verify: persists across restart   ← parallel with 0
Step 2  AnalyticsService               verify: unit test with known data  ← parallel with 0–1
Step 3  AnalyticsProvider              verify: recompute transitions      ← needs 2
Step 4  main.dart registration         ← needs 3
Step 5  AnalyticsScreen                verify: 3 states + nerd mode card  ← needs 3, 4
Step 6  Settings nerd mode toggle      verify: persists                   ← needs 1
Step 7  HomeScreen tab                 verify: navigates, no index error  ← needs 5
```

Steps 0, 1, 2 can be implemented simultaneously. Step 5 is the largest.
