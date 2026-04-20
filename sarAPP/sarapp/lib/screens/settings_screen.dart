import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/custom_module.dart';
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
    final settings = context.read<SettingsProvider>().settings;
    await ExportService.exportToCsv(entries, settings);
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

        // ── About ─────────────────────────────────────────────────────────
        const _Header('About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About sarAPP'),
          subtitle: const Text('What this app is and how it works'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutScreen()),
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

// ── Shared helper ─────────────────────────────────────────────────────────────

AppModule? _builtinForKey(String key) {
  final matches = AppModule.all.where((m) => m.key == key);
  return matches.isEmpty ? null : matches.first;
}

// ── Modules sub-screen (reorderable) ─────────────────────────────────────────

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  void _onReorder(
      int oldIndex, int newIndex, List<String> visibleKeys, AppSettings settings,
      BuildContext context) {
    if (newIndex > oldIndex) newIndex--;
    final newVisible = List<String>.from(visibleKeys);
    final moved = newVisible.removeAt(oldIndex);
    newVisible.insert(newIndex, moved);
    // Reconstruct full order keeping hidden modules at their sorted positions
    final fullOrder = List<String>.from(settings.moduleOrder);
    final visibleIndices = visibleKeys
        .map(fullOrder.indexOf)
        .toList()
      ..sort();
    for (var i = 0; i < visibleIndices.length; i++) {
      fullOrder[visibleIndices[i]] = newVisible[i];
    }
    context.read<SettingsProvider>().update(
          settings.copyWith(moduleOrder: fullOrder));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    final visibleKeys = settings.moduleOrder.where((key) {
      final builtin = _builtinForKey(key);
      if (builtin != null) {
        return !builtin.menstruationOnly || settings.isMenstruationTracking;
      }
      return settings.customModules.any((m) => m.id == key);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire modules')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModuleEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(Icons.drag_indicator_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag (press long) to reorder. Tap ✏️ to customise.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: visibleKeys.length,
              onReorder: (oldIdx, newIdx) =>
                  _onReorder(oldIdx, newIdx, visibleKeys, settings, context),
              itemBuilder: (ctx, index) {
                final key = visibleKeys[index];
                final builtin = _builtinForKey(key);
                final custom = builtin == null
                    ? settings.customModules
                        .where((m) => m.id == key)
                        .cast<CustomModule?>()
                        .firstWhere((_) => true, orElse: () => null)
                    : null;

                final emojiStr =
                    builtin?.emoji ?? (custom?.emoji.isNotEmpty == true ? custom!.emoji : null);
                final label = builtin?.label ?? custom?.name ?? key;
                final subtitle = builtin != null
                    ? (settings.customModuleQuestions[key] ?? builtin.description)
                    : (custom?.question ?? '');

                return ListTile(
                  key: Key(key),
                  leading: emojiStr != null
                      ? Text(emojiStr, style: const TextStyle(fontSize: 20))
                      : const Icon(Icons.tune),
                  title: Text(label),
                  subtitle: Text(subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit module',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ModuleEditScreen(moduleKey: key),
                          ),
                        ),
                      ),
                      Switch(
                        value: settings.isModuleEnabled(key),
                        onChanged: (_) => context
                            .read<SettingsProvider>()
                            .update(settings.withModuleToggled(key)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Customize modules screen ──────────────────────────────────────────────────

class CustomizeModulesScreen extends StatelessWidget {
  const CustomizeModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Customize modules')),
      body: ListView(
        children: settings.moduleOrder.map((key) {
          final builtin = _builtinForKey(key);
          if (builtin != null) {
            return ListTile(
              leading: Text(builtin.emoji,
                  style: const TextStyle(fontSize: 20)),
              title: Text(builtin.label),
              subtitle: Text(
                settings.customModuleQuestions[key] ?? builtin.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ModuleEditScreen(moduleKey: key),
                ),
              ),
            );
          }
          final customMatches =
              settings.customModules.where((m) => m.id == key);
          if (customMatches.isEmpty) return const SizedBox.shrink();
          final custom = customMatches.first;
          return ListTile(
            leading: custom.emoji.isNotEmpty
                ? Text(custom.emoji, style: const TextStyle(fontSize: 20))
                : const Icon(Icons.tune),
            title: Text(custom.name),
            subtitle: Text(custom.question,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ModuleEditScreen(moduleKey: key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Per-module edit screen ────────────────────────────────────────────────────

class ModuleEditScreen extends StatefulWidget {
  final String? moduleKey; // null = create new custom module

  const ModuleEditScreen({super.key, this.moduleKey});

  @override
  State<ModuleEditScreen> createState() => _ModuleEditScreenState();
}

class _ModuleEditScreenState extends State<ModuleEditScreen> {
  AppModule? _builtin;
  CustomModule? _custom;

  late TextEditingController _questionCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _emojiCtrl;
  late TextEditingController _optionAddCtrl;
  late TextEditingController _conditionalTriggerCtrl;
  late TextEditingController _conditionalQuestionCtrl;
  late TextEditingController _conditionalOptionAddCtrl;
  late TextEditingController _labelLowCtrl;
  late TextEditingController _labelHighCtrl;
  late ResponseType _responseType;
  late List<String> _options;
  late List<String> _conditionalOptions;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;

    if (widget.moduleKey != null) {
      final builtinMatches =
          AppModule.all.where((m) => m.key == widget.moduleKey);
      _builtin = builtinMatches.isEmpty ? null : builtinMatches.first;
      if (_builtin == null) {
        final customMatches =
            settings.customModules.where((m) => m.id == widget.moduleKey);
        _custom = customMatches.isEmpty ? null : customMatches.first;
      }
    }

    if (_builtin != null) {
      _questionCtrl = TextEditingController(
          text: settings.customModuleQuestions[_builtin!.key] ?? '');
      _nameCtrl = TextEditingController();
      _emojiCtrl = TextEditingController();
      _responseType = _builtin!.responseType;
      _options = List.from(settings.moduleOptions[_builtin!.key] ?? _builtin!.defaultOptions);
      _conditionalTriggerCtrl = TextEditingController();
      _conditionalQuestionCtrl = TextEditingController();
      _conditionalOptions = [];
      _labelLowCtrl = TextEditingController(text: settings.labelLowFor(_builtin!.key));
      _labelHighCtrl = TextEditingController(text: settings.labelHighFor(_builtin!.key));
    } else if (_custom != null) {
      _questionCtrl = TextEditingController(text: _custom!.question);
      _nameCtrl = TextEditingController(text: _custom!.name);
      _emojiCtrl = TextEditingController(text: _custom!.emoji);
      _responseType = _custom!.responseType;
      _options = List.from(_custom!.options);
      _conditionalTriggerCtrl = TextEditingController(text: _custom!.conditionalTrigger ?? '');
      _conditionalQuestionCtrl = TextEditingController(text: _custom!.conditionalQuestion ?? '');
      _conditionalOptions = List.from(_custom!.conditionalOptions);
      _labelLowCtrl = TextEditingController(text: _custom!.labelLow);
      _labelHighCtrl = TextEditingController(text: _custom!.labelHigh);
    } else {
      _questionCtrl = TextEditingController();
      _nameCtrl = TextEditingController();
      _emojiCtrl = TextEditingController();
      _responseType = ResponseType.scale;
      _options = [];
      _conditionalTriggerCtrl = TextEditingController();
      _conditionalQuestionCtrl = TextEditingController();
      _conditionalOptions = [];
      _labelLowCtrl = TextEditingController();
      _labelHighCtrl = TextEditingController();
    }
    _optionAddCtrl = TextEditingController();
    _conditionalOptionAddCtrl = TextEditingController();

    for (final ctrl in [
      _questionCtrl, _nameCtrl, _emojiCtrl,
      _conditionalTriggerCtrl, _conditionalQuestionCtrl,
      _labelLowCtrl, _labelHighCtrl,
    ]) {
      ctrl.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _optionAddCtrl.dispose();
    _conditionalTriggerCtrl.dispose();
    _conditionalQuestionCtrl.dispose();
    _conditionalOptionAddCtrl.dispose();
    _labelLowCtrl.dispose();
    _labelHighCtrl.dispose();
    super.dispose();
  }

  bool get _hasOptionList =>
      _responseType == ResponseType.multiSelect ||
      _responseType == ResponseType.singleSelect ||
      _responseType == ResponseType.conditional;

  void _addOption() {
    final v = _optionAddCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _options.add(v);
      _optionAddCtrl.clear();
      _isDirty = true;
    });
  }

  void _addConditionalOption() {
    final v = _conditionalOptionAddCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _conditionalOptions.add(v);
      _conditionalOptionAddCtrl.clear();
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>().settings;

    if (_builtin != null) {
      final question = _questionCtrl.text.trim();
      final questionMap =
          Map<String, String>.from(settings.customModuleQuestions);
      if (question.isEmpty) {
        questionMap.remove(_builtin!.key);
      } else {
        questionMap[_builtin!.key] = question;
      }
      var updated = settings.copyWith(customModuleQuestions: questionMap);

      if (_hasOptionList) {
        final opts = Map<String, List<String>>.from(settings.moduleOptions);
        opts[_builtin!.key] = List.from(_options);
        updated = updated.copyWith(moduleOptions: opts);
      }

      if (_responseType == ResponseType.scale) {
        final ll = _labelLowCtrl.text.trim();
        final lh = _labelHighCtrl.text.trim();
        final low = Map<String, String>.from(settings.moduleLabelLow);
        final high = Map<String, String>.from(settings.moduleLabelHigh);
        ll.isEmpty ? low.remove(_builtin!.key) : low[_builtin!.key] = ll;
        lh.isEmpty ? high.remove(_builtin!.key) : high[_builtin!.key] = lh;
        updated = updated.copyWith(moduleLabelLow: low, moduleLabelHigh: high);
      }

      await context.read<SettingsProvider>().update(updated);
    } else if (_custom != null) {
      final name = _nameCtrl.text.trim();
      final question = _questionCtrl.text.trim();
      if (name.isEmpty || question.isEmpty) return;
      final trigger = _conditionalTriggerCtrl.text.trim();
      final condQuestion = _conditionalQuestionCtrl.text.trim();
      final updatedModule = CustomModule(
        id: _custom!.id,
        name: name,
        emoji: _emojiCtrl.text.trim(),
        question: question,
        responseType: _responseType,
        options: List.from(_options),
        conditionalTrigger: trigger.isEmpty ? null : trigger,
        conditionalQuestion: condQuestion.isEmpty ? null : condQuestion,
        conditionalOptions: List.from(_conditionalOptions),
        labelLow: _labelLowCtrl.text.trim(),
        labelHigh: _labelHighCtrl.text.trim(),
      );
      await context.read<SettingsProvider>().update(settings.copyWith(
            customModules: settings.customModules
                .map((m) => m.id == _custom!.id ? updatedModule : m)
                .toList(),
          ));
    } else {
      final name = _nameCtrl.text.trim();
      final question = _questionCtrl.text.trim();
      if (name.isEmpty || question.isEmpty) return;
      final trigger = _conditionalTriggerCtrl.text.trim();
      final condQuestion = _conditionalQuestionCtrl.text.trim();
      final newModule = CustomModule.create(
        name: name,
        emoji: _emojiCtrl.text.trim(),
        question: question,
        responseType: _responseType,
        options: List.from(_options),
        conditionalTrigger: trigger.isEmpty ? null : trigger,
        conditionalQuestion: condQuestion.isEmpty ? null : condQuestion,
        conditionalOptions: List.from(_conditionalOptions),
        labelLow: _labelLowCtrl.text.trim(),
        labelHigh: _labelHighCtrl.text.trim(),
      );
      await context.read<SettingsProvider>().update(settings.copyWith(
            customModules: [...settings.customModules, newModule],
            enabledModules: {...settings.enabledModules, newModule.id},
            moduleOrder: [...settings.moduleOrder, newModule.id],
          ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteModule() async {
    final settings = context.read<SettingsProvider>().settings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${_custom!.name}"?'),
        content: const Text(
          'This module will be removed from your questionnaire. '
          'Past responses are kept silently in your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // ignore: use_build_context_synchronously
    await context.read<SettingsProvider>().update(settings.copyWith(
          customModules:
              settings.customModules.where((m) => m.id != _custom!.id).toList(),
          enabledModules: Set<String>.from(settings.enabledModules)
            ..remove(_custom!.id),
          moduleOrder:
              settings.moduleOrder.where((k) => k != _custom!.id).toList(),
        ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = _builtin != null
        ? '${_builtin!.emoji} ${_builtin!.label}'
        : _custom != null
            ? 'Edit module'
            : 'New module';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved edits. Discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (leave == true && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_builtin == null) ...[
            Row(children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _emojiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Module name *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _questionCtrl,
            decoration: InputDecoration(
              labelText: 'Question',
              hintText: _builtin != null ? _builtin!.description : null,
              helperText: _builtin != null ? 'Leave blank to use the default above' : null,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text('Response type', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ResponseType.values.map((rt) {
              final label = switch (rt) {
                ResponseType.scale => '0–10 Scale',
                ResponseType.multiSelect => 'Multi-select',
                ResponseType.singleSelect => 'Single-select',
                ResponseType.text => 'Free text',
                ResponseType.conditional => 'Conditional',
              };
              if (_builtin != null) {
                return rt == _responseType
                    ? Chip(label: Text(label))
                    : const SizedBox.shrink();
              }
              return ChoiceChip(
                label: Text(label),
                selected: _responseType == rt,
                onSelected: (_) => setState(() {
                  _responseType = rt;
                  _isDirty = true;
                  if (rt != ResponseType.multiSelect &&
                      rt != ResponseType.singleSelect &&
                      rt != ResponseType.conditional) {
                    _options.clear();
                  }
                  if (rt != ResponseType.conditional) {
                    _conditionalOptions.clear();
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_responseType == ResponseType.scale) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _labelLowCtrl,
                  decoration: InputDecoration(
                    labelText: 'Low label',
                    hintText: _builtin?.labelLow.isNotEmpty == true
                        ? _builtin!.labelLow
                        : '0',
                    helperText: 'Emoji or text for the low end',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _labelHighCtrl,
                  decoration: InputDecoration(
                    labelText: 'High label',
                    hintText: _builtin?.labelHigh.isNotEmpty == true
                        ? _builtin!.labelHigh
                        : '10',
                    helperText: 'Emoji or text for the high end',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (_hasOptionList) ...[
            Text(
              _responseType == ResponseType.conditional
                  ? 'Primary options'
                  : 'Answer options',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ..._options.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() { _options.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _optionAddCtrl,
              hint: 'e.g. 😊 Happy',
              onAdd: _addOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_builtin == null && _responseType == ResponseType.conditional) ...[
            TextField(
              controller: _conditionalTriggerCtrl,
              decoration: const InputDecoration(
                labelText: 'Trigger option',
                hintText: 'Which option reveals the follow-up?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditionalQuestionCtrl,
              decoration: const InputDecoration(
                labelText: 'Follow-up question (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Follow-up options', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ..._conditionalOptions.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() { _conditionalOptions.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _conditionalOptionAddCtrl,
              hint: 'Add a follow-up option',
              onAdd: _addConditionalOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_custom != null) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Remove module',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Past responses are kept in your data'),
              onTap: _deleteModule,
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _AddItemRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  const _AddItemRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAdd,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── About screen ──────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('About sarAPP')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App identity
          Center(
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 56, color: primary),
                const SizedBox(height: 12),
                Text('sarAPP',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('v0.1 · Free, open-source, and made with ❤️',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: outline)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Philosophy
          _AboutSection(
            icon: Icons.tune,
            title: 'Track what you choose',
            body:
                'sarAPP lets you track different dimensions of your day. Everyone is different.' 
                'You decide what dimensions matter to you. Enable or '
                'disable any module at any time in Settings. '
                'There is no required field.',
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.lock_outline,
            title: 'Your data, your device',
            body:
                'Everything you log stays on your phone. No account, no cloud '
                'sync, (currenty) no analytics. Your data is stored locally in a private '
                'database and can be exported to a CSV whenever you want.',
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.code,
            title: 'Free and open-source',
            body:
                'sarAPP is free to use and its source code is open. You can '
                'inspect exactly what it does, contribute improvements, or '
                'adapt it for your own needs.',
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Data always stays on your device.',
              style: theme.textTheme.bodySmall?.copyWith(color: outline),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AboutSection(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
