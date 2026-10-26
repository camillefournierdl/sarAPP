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
        const SnackBar(content: Text('No entries to export yet.')),
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
        const SnackBar(content: Text('Could not read this backup file.')),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import backup?'),
        content: Text(
            'This will import ${data.entries.length} entries and restore '
            'your modules, options, and preferences from the backup.\n\n'
            'Entries already logged on the same dates will be overwritten. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
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
      SnackBar(content: Text('Imported ${data.entries.length} entries.')),
    );
  }

  String _startDayLabel(String pref) => pref == 'sunday' ? 'Sunday' : 'Monday';

  Future<void> _pickStartDay(AppSettings settings) async {
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Week starts on'),
        children: [
          _StartDayOption(ctx, label: 'Monday', value: 'monday', current: settings.calendarStartDay),
          _StartDayOption(ctx, label: 'Sunday', value: 'sunday', current: settings.calendarStartDay),
        ],
      ),
    );
    if (!mounted || picked == null || picked == settings.calendarStartDay) return;
    // ignore: use_build_context_synchronously
    await context.read<SettingsProvider>().update(
          settings.copyWith(calendarStartDay: picked),
        );
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
      const SnackBar(
          content: Text(
              'Notifications are blocked. Allow them in system settings to get reminders.')),
    );
  }

  Future<void> _pickTime() async {
    final settings = context.read<SettingsProvider>().settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: settings.notificationHour,
          minute: settings.notificationMinute),
      helpText: 'Pick reminder time',
    );
    if (picked == null || !mounted) return;
    await _setReminder(true, time: picked);
  }

  Future<void> _seedTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seed test data?'),
        content: const Text(
          'Inserts 60 synthetic entries with known correlations for '
          'testing the Analytics tab.\n\n'
          'Existing entries on those dates will be overwritten.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seed'),
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
        title: const Text('Reset all data?'),
        content: const Text(
            'This will permanently delete all your logged entries and '
            'clear your cycle baseline. Your tracking mode will be kept.\n\n'
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<EntriesProvider>().clearAll();
    await context.read<SettingsProvider>().clearPeriodBaseline();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return ListView(
      children: [
        // ── Questionnaire modules ─────────────────────────────────────────
        const _Header('Questionnaire modules'),
        ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('Questionnaire modules'),
          subtitle: Text(
            '${settings.enabledModules.length} active',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ModulesScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note),
          title: const Text('Customize modules'),
          subtitle: const Text('Edit question, options, or delete'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomizeModulesScreen()),
          ),
        ),

        // ── Tracking ──────────────────────────────────────────────────────
        const _Header('Tracking'),
        SwitchListTile(
          secondary: const Icon(Icons.favorite_outline),
          title: const Text('Menstruation tracking'),
          subtitle: const Text('Enable cycle phases, period dates & symptoms'),
          value: settings.isMenstruationTracking,
          onChanged: _toggleMenstruationTracking,
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Week starts on'),
          subtitle: Text(_startDayLabel(settings.calendarStartDay)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickStartDay(settings),
        ),

        // ── Cycle stats (female only) ─────────────────────────────────────
        if (settings.isMenstruationTracking) ...[
          const _Header('Cycle'),
          _CycleStatsCard(entries: context.watch<EntriesProvider>().entries),
          SwitchListTile(
            secondary: const Icon(Icons.child_friendly_outlined),
            title: const Text('Show higher-fertility window'),
            subtitle: const Text(
                'Highlights the ~5 days of elevated fertility around ovulation'),
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
              title: const Text('Show intimacy'),
              subtitle: const Text(
                  'A pink dot indicates tracked activity in the calendar'),
              value: settings.showLastSex,
              onChanged: (v) => context
                  .read<SettingsProvider>()
                  .update(settings.copyWith(showLastSex: v)),
            ),
        ],

        // ── Reminder ──────────────────────────────────────────────────────
        const _Header('Reminder'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Daily reminder'),
          subtitle: const Text('Get a nudge to log your day'),
          value: settings.notificationsEnabled,
          onChanged: (v) => _setReminder(v),
        ),
        if (settings.notificationsEnabled)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Reminder time'),
            subtitle: Text(TimeOfDay(
                    hour: settings.notificationHour,
                    minute: settings.notificationMinute)
                .format(context)),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _pickTime,
          ),

        // ── Data ──────────────────────────────────────────────────────────
        const _Header('Data'),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export to CSV'),
          subtitle: const Text('Share or save your data'),
          onTap: _export,
        ),
        ListTile(
          leading: Icon(Icons.delete_forever,
              color: Theme.of(context).colorScheme.error),
          title: Text('Reset all data',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error)),
          subtitle: const Text('Delete all entries and cycle baseline'),
          onTap: _resetData,
        ),

        // ── Analytics (placeholder until the feature ships) ──────────────
        if (!kAnalyticsEnabled) ...[
          const _Header('Analytics'),
          const SwitchListTile(
            secondary: Icon(Icons.insights),
            title: Text('Insights & correlations'),
            subtitle: Text(
                'Coming in a future version: see how your mood, sleep and '
                'symptoms relate to each other.'),
            value: false,
            onChanged: null,
          ),
        ],

        // ── About ─────────────────────────────────────────────────────────
        const _Header('About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About sarapp'),
          subtitle: const Text('What this app is and how it works'),
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
            title: const Text('Advanced'),
            subtitle: Text(kAnalyticsEnabled
                ? 'Nerd mode, developer tools & backup'
                : 'Backup & restore'),
            initiallyExpanded: false,
            children: [
              if (kAnalyticsEnabled) SwitchListTile(
                secondary: const Icon(Icons.science_outlined),
                title: const Text('Nerd mode'),
                subtitle:
                    const Text('Show statistical details in analytics'),
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
                title: const Text('Seed test data'),
                subtitle: const Text(
                    'Insert 60 synthetic entries for Analytics testing'),
                onTap: _isSeeding ? null : _seedTestData,
              ),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup data (JSON)'),
                subtitle: const Text(
                    'Full backup — use to move to a new install'),
                onTap: _exportBackup,
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Import backup'),
                subtitle: const Text(
                    'Restore entries and settings from a JSON backup'),
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

    String cycleLabel;
    String cycleNote;
    if (stats.cyclesLogged == 0) {
      cycleLabel = '28 days (default)';
      cycleNote = 'Log at least 2 period starts to personalise';
    } else {
      cycleLabel = '${stats.cycleLength} days';
      cycleNote = 'Based on ${stats.cyclesLogged} '
          '${stats.cyclesLogged == 1 ? 'cycle' : 'cycles'}';
    }

    String periodLabel;
    String periodNote;
    if (stats.periodsLogged == 0) {
      periodLabel = '5 days (default)';
      periodNote = 'Log a period start + end to personalise';
    } else {
      periodLabel = '${stats.periodLength} days';
      periodNote = 'Based on ${stats.periodsLogged} '
          '${stats.periodsLogged == 1 ? 'period' : 'periods'}';
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
              Text('Your cycle statistics',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: primary)),
              const SizedBox(height: 12),
              _StatRow(
                label: 'Cycle length',
                value: cycleLabel,
                note: cycleNote,
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: 'Period length',
                value: periodLabel,
                note: periodNote,
              ),
              if (stats.cyclesLogged > 0 || stats.periodsLogged > 0) ...[
                const Divider(height: 20),
                Text('Estimated phases',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 8),
                _PhaseRow('Menstruation', '$P days', const Color(0xFFEF5350)),
                _PhaseRow(
                    'Follicular',
                    follicular > 0 ? '$follicular days' : '—',
                    const Color(0xFF66BB6A)),
                _PhaseRow('Ovulation', '1 day', const Color(0xFF42A5F5)),
                _PhaseRow('Luteal', '14 days', const Color(0xFFAB47BC)),
                const SizedBox(height: 4),
                Text(
                  'Luteal phase is fixed at 14 days (scientifically constant).',
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline)),
          ],
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

// ── Start-day dialog option ───────────────────────────────────────────────────

Widget _StartDayOption(
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
