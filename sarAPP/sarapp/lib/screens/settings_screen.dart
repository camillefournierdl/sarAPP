import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/entry.dart';
import '../models/app_module.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cycle_service.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _export() async {
    final entries = context.read<EntriesProvider>().entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to export yet.')),
      );
      return;
    }
    await ExportService.exportToCsv(entries);
  }

  String _startDayLabel(String? pref) {
    if (pref == 'monday') return 'Monday';
    if (pref == 'sunday') return 'Sunday';
    return 'Device default';
  }

  Future<void> _pickStartDay(AppSettings settings) async {
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Week starts on'),
        children: [
          _StartDayOption(ctx, label: 'Device default', value: null,    current: settings.calendarStartDay),
          _StartDayOption(ctx, label: 'Monday',         value: 'monday', current: settings.calendarStartDay),
          _StartDayOption(ctx, label: 'Sunday',         value: 'sunday', current: settings.calendarStartDay),
        ],
      ),
    );
    if (!mounted || picked == settings.calendarStartDay) return;
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
    await context
        .read<SettingsProvider>()
        .setNotification(enabled: enabled, hour: hour, minute: minute);
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted || !mounted) return;
      await NotificationService.scheduleDailyReminder(hour, minute);
    } else {
      await NotificationService.cancelAll();
    }
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
                .update(settings.copyWith(showHighFertility: v)),
          ),
        ],

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

        // ── About ─────────────────────────────────────────────────────────
        const _Header('About'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('sarAPP v0.1'),
          subtitle: Text('Mood & cycle tracker — data stays on your device'),
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
  required String? value,
  required String? current,
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

// ── Modules sub-screen ────────────────────────────────────────────────────────

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire modules')),
      body: ListView(
        children: AppModule.all
            .where((m) => !m.menstruationOnly || settings.isMenstruationTracking)
            .map((m) => SwitchListTile(
                  secondary: Text(m.emoji,
                      style: const TextStyle(fontSize: 20)),
                  title: Text(m.label),
                  subtitle: Text(m.description),
                  value: settings.isModuleEnabled(m.key),
                  onChanged: (_) => context
                      .read<SettingsProvider>()
                      .update(settings.withModuleToggled(m.key)),
                ))
            .toList(),
      ),
    );
  }
}
