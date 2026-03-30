import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/emotion_tag_selector.dart';
import '../widgets/symptom_selector.dart';

class LogEntryScreen extends StatefulWidget {
  /// Pass an existing entry to edit, or null to create a new one.
  /// Provide [date] (YYYY-MM-DD) when creating a new entry for a specific day.
  final Entry? existing;
  final String? date;

  const LogEntryScreen({super.key, this.existing, this.date});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  late String _date;
  late List<String> _emotions;
  String? _cyclePhase;
  late bool _periodStart;
  late bool _periodEnd;
  late List<String> _symptoms;
  // null = user hasn't rated; becomes 0–10 once the slider is touched
  int? _happinessScore;
  late List<String> _foods;
  late List<String> _activities;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? widget.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _emotions = List.from(e?.emotions ?? []);
    _cyclePhase = e?.cyclePhase;
    _periodStart = e?.periodStart ?? false;
    _periodEnd = e?.periodEnd ?? false;
    _symptoms = List.from(e?.symptoms ?? []);
    _happinessScore = e?.happinessScore;
    _foods = List.from(e?.foods ?? []);
    _activities = List.from(e?.activities ?? []);
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _appBarTitle() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_date == today) return widget.existing == null ? 'Log today' : 'Edit today';
    return DateFormat('MMM d, yyyy').format(DateTime.parse(_date));
  }

  Future<void> _save() async {
    final entry = Entry.create(
      date: _date,
      emotions: _emotions,
      cyclePhase: _cyclePhase,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      symptoms: _symptoms,
      happinessScore: _happinessScore,
      foods: _foods,
      activities: _activities,
      notes: _notesController.text.trim(),
    );
    await context.read<EntriesProvider>().saveEntry(entry);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isFemale =
        context.watch<SettingsProvider>().settings.isFemaleMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date display
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_date)),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),

          // ── Happiness scale ─────────────────────────────────────────────
          _Section(
            title: 'How happy did you feel today? (0 – 10)',
            child: _HappinessSlider(
              value: _happinessScore,
              onChanged: (v) => setState(() => _happinessScore = v),
            ),
          ),

          // ── Emotions ───────────────────────────────────────────────────
          const SizedBox(height: 16),
          _Section(
            title: 'How are you feeling?',
            child: EmotionTagSelector(
              selected: _emotions,
              onChanged: (v) => setState(() => _emotions = v),
            ),
          ),

          // ── Physical activity ────────────────────────────────────────────
          const SizedBox(height: 16),
          _Section(
            title: 'Physical activity today?',
            child: _ChipSelector(
              options: const [
                '🏋️ Weight lifting',
                '🏃 Intense cardio',
                '🚴 Endurance',
                '💃 Dance',
                '🧗 Climbing',
              ],
              selected: _activities,
              onChanged: (v) => setState(() => _activities = v),
            ),
          ),

          // ── Food ────────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _Section(
            title: 'What did you eat today?',
            child: _ChipSelector(
              options: const [
                '🌾 Gluten',
                '🥛 Lactose',
                '🍬 Sugars',
              ],
              selected: _foods,
              onChanged: (v) => setState(() => _foods = v),
            ),
          ),

          // ── Symptoms (female + setting enabled) ─────────────────────────
          if (isFemale &&
              context.watch<SettingsProvider>().settings.showSymptoms) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Symptoms',
              child: SymptomSelector(
                selected: _symptoms,
                onChanged: (v) => setState(() => _symptoms = v),
              ),
            ),
          ],

          // ── Notes ───────────────────────────────────────────────────────
          const SizedBox(height: 16),
          _Section(
            title: 'Notes',
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Anything else on your mind…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Happiness slider ──────────────────────────────────────────────────────────

class _HappinessSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _HappinessSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        const Text('0', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Slider(
            value: (value ?? 5).toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: value == null ? '—' : '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        const Text('10', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        // Shows the current value, or "—" if untouched
        SizedBox(
          width: 36,
          child: Text(
            value == null ? '—' : '$value / 10',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value == null ? Colors.grey : primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Generic multi-select chip row ─────────────────────────────────────────────

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (on) {
            final updated = List<String>.from(selected);
            if (on) {
              updated.add(opt);
            } else {
              updated.remove(opt);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
