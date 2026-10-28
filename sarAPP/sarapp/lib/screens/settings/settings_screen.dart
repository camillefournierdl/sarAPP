import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feature_flags.dart';
import '../../models/app_settings.dart';
import '../../models/entry.dart';
import '../../providers/entries_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../services/cycle_service.dart';
import '../../services/database_service.dart';
import '../../services/export_service.dart';
import 'about_screen.dart';
import 'modules_screen.dart';
import '../../l10n/l10n_helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSeeding = false;

  Future<void> _export() async {
    final entries = context.read<EntriesProvider>().entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noEntriesToExport)),
      );
      return;
    }
    final settings = context.read<SettingsProvider>().settings;
    await ExportService.exportToCsv(entries, settings);
  }

  Future<void> _exportBackup() async {
    final entries = context.read<EntriesProvider>().entries;
    final settings = context.read<SettingsProvider>().settings;
    await BackupService.exportToJson(entries, settings);
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    BackupData data;
    try {
      final content = await File(path).readAsString();
      data = BackupService.parseBackup(content);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.backupReadError)),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.importBackupTitle),
        content: Text(context.l10n.importBackupBody(data.entries.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.importAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await DatabaseService.upsertEntries(data.entries);
    if (!mounted) return;
    await context.read<EntriesProvider>().load();
    if (!mounted) return;
    await context.read<SettingsProvider>().update(data.settings);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.importedEntries(data.entries.length))),
    );
  }

  String _startDayLabel(String pref) =>
      pref == 'sunday' ? context.l10n.sunday : context.l10n.monday;

  Future<void> _pickStartDay(AppSettings settings) async {
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.weekStartsOn),
        children: [
          _RadioOption(ctx, label: ctx.l10n.monday, value: 'monday', current: settings.calendarStartDay),
          _RadioOption(ctx, label: ctx.l10n.sunday, value: 'sunday', current: settings.calendarStartDay),
        ],
      ),
    );
    if (!mounted || picked == null || picked == settings.calendarStartDay) return;
    // ignore: use_build_context_synchronously
    await context.read<SettingsProvider>().update(
          settings.copyWith(calendarStartDay: picked),
        );
  }

  String _languageLabel(String? code) =>
      languageNames[code] ?? context.l10n.languageSystem;

  Future<void> _pickLanguage(AppSettings settings) async {
    // 'system' stands in for null, which showDialog uses for "dismissed".
    final current = settings.languageCode ?? 'system';
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.language),
        children: [
          _RadioOption(ctx, label: _languageLabel(null), value: 'system', current: current),
          for (final MapEntry(key: code, value: name) in languageNames.entries)
            _RadioOption(ctx, label: name, value: code, current: current),
        ],
      ),
    );
    if (!mounted || picked == null || picked == current) return;
    // ignore: use_build_context_synchronously
    await context
        .read<SettingsProvider>()
        .setLanguage(picked == 'system' ? null : picked);
  }

  Future<void> _toggleMenstruationTracking(bool enabled) async {
    final settings = context.read<SettingsProvider>().settings;
    await context
        .read<SettingsProvider>()
        .update(settings.copyWith(menstruationTracking: enabled));
  }

  Future<void> _setReminder(bool enabled, {TimeOfDay? time}) async {
    final settings = context.read<SettingsProvider>().settings;
    final hour = time?.hour ?? settings.notificationHour;
    final minute = time?.minute ?? settings.notificationMinute;
    final ok = await context
        .read<SettingsProvider>()
        .setNotification(enabled: enabled, hour: hour, minute: minute);
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.notificationsBlocked)),
    );
  }

  Future<void> _pickTime() async {
    final settings = context.read<SettingsProvider>().settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: settings.notificationHour,
          minute: settings.notificationMinute),
      helpText: context.l10n.pickReminderTime,
    );
    if (picked == null || !mounted) return;
    await _setReminder(true, time: picked);
  }

  Future<void> _seedTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('seed test data?'),
        content: const Text(
          'inserts 60 synthetic entries with known correlations for '
          'testing the analytics tab.\n\n'
          'existing entries on those dates will be overwritten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('seed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);

    final now = DateTime.now();
    // 60 entries with realistic variation across all default-enabled modules.
    // Structure: 7-day phase cycle (bad → neutral → good) + per-day hash noise.
    // Known correlations planted:
    //   happiness ↔ sleep (Spearman), health=Sick → lower scores (MW),
    //   emotions/leisure follow phase, food/weather mostly independent.
    for (var i = 0; i < 60; i++) {
      // Deterministic pseudo-random: independent sequence per salt.
      int r(int salt) =>
          ((i * 1664525 + salt * 22695477 + 1013904223) ^
                  ((i * 22695477 + salt * 1664525) >> 14)) %
              100;

      final d = now.subtract(Duration(days: 59 - i));
      final dateStr = '${d.year}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      // 3-phase weekly cycle: 0 = rough, 1 = average, 2 = good
      final phase = (i ~/ 7) % 3;
      final base = [2, 5, 7][phase];

      // ── Scores (correlated via shared phase base) ──────────────────────
      final happiness = (base + r(1) % 5 - 2).clamp(1, 10);
      final sleep     = (base + r(2) % 5 - 2).clamp(1, 10);
      final weather   = (4 + r(20) % 7 - 2).clamp(1, 10); // mostly independent

      // ── Health (Sick on some low-happiness days) ───────────────────────
      final isSick = happiness <= 3 && r(3) < 45;
      final healthStatus = isSick ? 'Sick' : 'Healthy';
      final sickTagPool = [
        '🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '😮‍💨 Fatigue',
      ];
      final sickTags = <String>[
        if (isSick)
          for (var j = 0; j < sickTagPool.length; j++)
            if (r(60 + j) < 40) sickTagPool[j],
        // guarantee at least one tag when sick
        if (isSick && r(66) < 40) sickTagPool[r(67) % sickTagPool.length],
      ];

      // ── Emotions (phase-weighted) ──────────────────────────────────────
      final emotions = <String>[
        if (phase == 2) ...[ // good week
          if (r(10) < 70) '😊 Happy',
          if (r(11) < 50) '⚡ Energized',
          if (r(12) < 15) '😰 Anxious',
        ] else if (phase == 0) ...[ // rough week
          if (r(10) < 65) '😴 Tired',
          if (r(11) < 50) '😰 Anxious',
          if (r(12) < 35) '😢 Sad',
          if (r(13) < 20) '😊 Happy',
        ] else ...[ // neutral week
          if (r(10) < 40) '😊 Happy',
          if (r(11) < 35) '😴 Tired',
          if (r(12) < 25) '😰 Anxious',
          if (r(13) < 20) '⚡ Energized',
        ],
      ];

      // ── Work (mostly full days, occasional half/off) ───────────────────
      final workRoll = r(30);
      final workDay = workRoll < 18 ? '🌿 Day off'
          : workRoll < 32 ? '🌗 Half day'
          : '💼 Full day';

      // ── Sports (more likely on good days) ─────────────────────────────
      final sportsPool = ['🏋️ Weight lifting', '🏃 Intense cardio', '🚴 Endurance'];
      final sports = <String>[
        if (happiness >= 6 && r(4) < 35) sportsPool[r(5) % sportsPool.length],
      ];

      // ── Leisure (more likely on good days or days off) ─────────────────
      final leisurePool = [
        '📖 Reading', '🎮 Gaming', '🎵 Music (practice)', '🌱 Gardening', '🎲 Board games',
      ];
      final threshold = phase == 2 ? 35 : phase == 1 ? 22 : 12;
      final leisure = <String>[
        for (var j = 0; j < leisurePool.length; j++)
          if (r(40 + j) < threshold) leisurePool[j],
      ];

      // ── Food (random; slight junk bias on rough days) ──────────────────
      final foodPool = ['🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish'];
      final foods = <String>[
        for (var j = 0; j < foodPool.length; j++)
          if (r(50 + j) < (j <= 2 && phase == 0 ? 45 : 28)) foodPool[j],
      ];

      await DatabaseService.upsertEntry(Entry.create(
        date: dateStr,
        happinessScore: happiness,
        sleepScore: sleep,
        weatherScore: weather,
        emotions: emotions,
        healthStatus: healthStatus,
        sickTags: sickTags,
        workDay: workDay,
        sports: sports,
        leisure: leisure,
        foods: foods,
        answeredModules: const {
          'happiness', 'sleep', 'weather', 'emotions',
          'health', 'work', 'sports', 'leisure', 'food',
        },
      ));
    }

    // Refresh the provider once rather than 60 times
    if (!mounted) return;
    await context.read<EntriesProvider>().load();

    if (!mounted) return;
    setState(() => _isSeeding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('60 test entries seeded.')),
    );
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.resetTitle),
        content: Text(context.l10n.resetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteEverything),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<EntriesProvider>().clearAll();
    await context.read<SettingsProvider>().clearPeriodBaseline();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.allDataDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final l10n = context.l10n;

    return ListView(
      children: [
        // ── Questionnaire modules ─────────────────────────────────────────
        _Header(l10n.sectionModules),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(l10n.sectionModules),
          subtitle: Text(l10n.modulesActive(settings.enabledModules.length)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ModulesScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: Text(l10n.customizeModules),
          subtitle: Text(l10n.customizeModulesSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomizeModulesScreen()),
          ),
        ),

        // ── Tracking ──────────────────────────────────────────────────────
        _Header(l10n.sectionTracking),
        SwitchListTile(
          secondary: const Icon(Icons.favorite_outline),
          title: Text(l10n.menstruationTracking),
          subtitle: Text(l10n.menstruationTrackingSubtitle),
          value: settings.isMenstruationTracking,
          onChanged: _toggleMenstruationTracking,
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(l10n.weekStartsOn),
          subtitle: Text(_startDayLabel(settings.calendarStartDay)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickStartDay(settings),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          subtitle: Text(_languageLabel(settings.languageCode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickLanguage(settings),
        ),

        // ── Cycle stats (female only) ─────────────────────────────────────
        if (settings.isMenstruationTracking) ...[
          _Header(l10n.sectionCycle),
          _CycleStatsCard(entries: context.watch<EntriesProvider>().entries),
          SwitchListTile(
            secondary: const Icon(Icons.child_friendly_outlined),
            title: Text(l10n.showFertility),
            subtitle: Text(l10n.showFertilitySubtitle),
            value: settings.showHighFertility,
            onChanged: (v) => context
                .read<SettingsProvider>()
                .update(settings.copyWith(
                  showHighFertility: v,
                  showLastSex: v ? settings.showLastSex : false,
                )),
          ),
          if (settings.showHighFertility)
            SwitchListTile(
              secondary: const Icon(Icons.favorite_outline),
              title: Text(l10n.showIntimacy),
              subtitle: Text(l10n.showIntimacySubtitle),
              value: settings.showLastSex,
              onChanged: (v) => context
                  .read<SettingsProvider>()
                  .update(settings.copyWith(showLastSex: v)),
            ),
        ],

        // ── Reminder ──────────────────────────────────────────────────────
        _Header(l10n.sectionReminder),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l10n.dailyReminder),
          subtitle: Text(l10n.dailyReminderSubtitle),
          value: settings.notificationsEnabled,
          onChanged: (v) => _setReminder(v),
        ),
        if (settings.notificationsEnabled)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(l10n.reminderTime),
            subtitle: Text(TimeOfDay(
                    hour: settings.notificationHour,
                    minute: settings.notificationMinute)
                .format(context)),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _pickTime,
          ),

        // ── Data ──────────────────────────────────────────────────────────
        _Header(l10n.sectionData),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text(l10n.exportCsv),
          subtitle: Text(l10n.exportCsvSubtitle),
          onTap: _export,
        ),
        ListTile(
          leading: Icon(Icons.delete_forever,
              color: Theme.of(context).colorScheme.error),
          title: Text(l10n.resetAllData,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error)),
          subtitle: Text(l10n.resetAllDataSubtitle),
          onTap: _resetData,
        ),

        // ── Analytics (placeholder until the feature ships) ──────────────
        if (!kAnalyticsEnabled) ...[
          _Header(l10n.sectionAnalytics),
          SwitchListTile(
            secondary: const Icon(Icons.insights),
            title: Text(l10n.insightsTitle),
            subtitle: Text(l10n.insightsComingSoon),
            value: false,
            onChanged: null,
          ),
        ],

        // ── About ─────────────────────────────────────────────────────────
        _Header(l10n.sectionAbout),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutApp),
          subtitle: Text(l10n.aboutAppSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
        ),

        // ── Advanced (collapsed by default) ─────────────────────────────────
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(l10n.advanced),
            subtitle: Text(kAnalyticsEnabled
                ? l10n.advancedSubtitleNerd
                : l10n.advancedSubtitle),
            initiallyExpanded: false,
            children: [
              if (kAnalyticsEnabled) SwitchListTile(
                secondary: const Icon(Icons.science_outlined),
                title: const Text('nerd mode'),
                subtitle:
                    const Text('show statistical details in analytics'),
                value: settings.analyticsNerdMode,
                onChanged: (v) => context
                    .read<SettingsProvider>()
                    .update(settings.copyWith(analyticsNerdMode: v)),
              ),
              // Overwrites real entries, so only offered in test releases.
              if (kAnalyticsEnabled) ListTile(
                leading: _isSeeding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science_outlined),
                title: const Text('seed test data'),
                subtitle: const Text(
                    'insert 60 synthetic entries for analytics testing'),
                onTap: _isSeeding ? null : _seedTestData,
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(l10n.backupJson),
                subtitle: Text(l10n.backupJsonSubtitle),
                onTap: _exportBackup,
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: Text(l10n.importBackup),
                subtitle: Text(l10n.importBackupSubtitle),
                onTap: _importBackup,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cycle stats card ──────────────────────────────────────────────────────────

class _CycleStatsCard extends StatelessWidget {
  final List<Entry> entries;
  const _CycleStatsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final stats = CycleService.cycleStats(entries);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = context.l10n;

    String cycleLabel;
    String cycleNote;
    if (stats.cyclesLogged == 0) {
      cycleLabel = l10n.daysDefault(28);
      cycleNote = l10n.cycleNoteDefault;
    } else {
      cycleLabel = l10n.daysCount(stats.cycleLength);
      cycleNote = l10n.cycleNoteBased(stats.cyclesLogged);
    }

    String periodLabel;
    String periodNote;
    if (stats.periodsLogged == 0) {
      periodLabel = l10n.daysDefault(5);
      periodNote = l10n.periodNoteDefault;
    } else {
      periodLabel = l10n.daysCount(stats.periodLength);
      periodNote = l10n.periodNoteBased(stats.periodsLogged);
    }

    // Derived phases (informational)
    final C = stats.cycleLength;
    final P = stats.periodLength;
    final follicular = C - P - 14; // days between end of period and ovulation

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cycleStatsTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: primary)),
              const SizedBox(height: 12),
              _StatRow(
                label: l10n.cycleLength,
                value: cycleLabel,
                note: cycleNote,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: l10n.periodLength,
                value: periodLabel,
                note: periodNote,
              ),
              if (stats.cyclesLogged > 0 || stats.periodsLogged > 0) ...[
                const Divider(height: 20),
                Text(l10n.estimatedPhases,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 8),
                _PhaseRow(l10n.phaseMenstruation, l10n.daysCount(P),
                    const Color(0xFFEF5350)),
                _PhaseRow(
                    l10n.phaseFollicular,
                    follicular > 0 ? l10n.daysCount(follicular) : '—',
                    const Color(0xFF66BB6A)),
                _PhaseRow(l10n.phaseOvulation, l10n.daysCount(1),
                    const Color(0xFF42A5F5)),
                _PhaseRow(l10n.phaseLuteal, l10n.daysCount(14),
                    const Color(0xFFAB47BC)),
                const SizedBox(height: 4),
                Text(
                  l10n.lutealFixedNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  const _StatRow(
      {required this.label, required this.value, required this.note});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 12),
        // Flexible so long (e.g. French) notes wrap instead of squeezing
        // the label down to one letter per line.
        Flexible(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(note,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final String phase;
  final String duration;
  final Color color;
  const _PhaseRow(this.phase, this.duration, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(phase,
                  style: Theme.of(context).textTheme.bodySmall)),
          Text(duration, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Radio-style dialog option ─────────────────────────────────────────────────────

Widget _RadioOption(
  BuildContext ctx, {
  required String label,
  required String value,
  required String current,
}) =>
    SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, value),
      child: Row(
        children: [
          Icon(
            current == value ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
