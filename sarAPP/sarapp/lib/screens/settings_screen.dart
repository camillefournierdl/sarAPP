import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cycle_service.dart';
import '../services/export_service.dart';

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

  Future<void> _switchMode() async {
    final settings = context.read<SettingsProvider>().settings;
    final newMode = settings.isFemaleMode ? 'male' : 'female';
    await context
        .read<SettingsProvider>()
        .update(settings.copyWith(userMode: newMode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Switched to ${newMode == "female" ? "Full tracking" : "Mood only"} mode.')),
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
        // ── Cycle stats (female only) ─────────────────────────────────────
        if (settings.isFemaleMode) ...[
          const _Header('Cycle'),
          _CycleStatsCard(
              entries: context
                  .watch<EntriesProvider>()
                  .entries),
        ],

        // ── Questionnaire options (female only) ───────────────────────────
        if (settings.isFemaleMode) ...[
          const _Header('Questionnaire'),
          SwitchListTile(
            secondary: const Icon(Icons.medical_information_outlined),
            title: const Text('Track symptoms'),
            subtitle: const Text('Show the symptoms question in the daily log'),
            value: settings.showSymptoms,
            onChanged: (v) => context
                .read<SettingsProvider>()
                .update(settings.copyWith(showSymptoms: v)),
          ),
        ],

        // ── Tracking mode ─────────────────────────────────────────────────
        const _Header('Tracking'),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: Text(settings.isFemaleMode
              ? 'Mode: Full tracking (mood + cycle)'
              : 'Mode: Mood only'),
          subtitle: const Text('Tap to switch'),
          onTap: _switchMode,
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
