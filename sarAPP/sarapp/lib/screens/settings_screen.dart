import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
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

  Future<void> _editPeriodDate() async {
    final settings = context.read<SettingsProvider>().settings;
    final current = settings.lastPeriodStart != null
        ? DateTime.parse(settings.lastPeriodStart!)
        : DateTime.now().subtract(const Duration(days: 14));

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'When did your last period start?',
    );
    if (picked == null || !mounted) return;
    await context
        .read<SettingsProvider>()
        .setPeriodBaseline(DateFormat('yyyy-MM-dd').format(picked));
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
    final periodLabel = settings.lastPeriodStart != null
        ? DateFormat('MMMM d, yyyy')
            .format(DateTime.parse(settings.lastPeriodStart!))
        : 'Not set';

    return ListView(
      children: [
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

        // ── Cycle baseline (female only) ───────────────────────────────────
        if (settings.isFemaleMode) ...[
          const _Header('Cycle'),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Last period start date'),
            subtitle: Text(periodLabel),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _editPeriodDate,
          ),
        ],

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
