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
  int? _sleepScore;
  late List<String> _foods;
  late List<String> _activities;
  late TextEditingController _notesController;
  int _step = 0;

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
    _sleepScore = e?.sleepScore;
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
      sleepScore: _sleepScore,
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
    final settings = context.watch<SettingsProvider>().settings;
    final isFemale = settings.isFemaleMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        // On step 2, override back to return to step 1 instead of leaving
        leading: _step == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = 0),
              )
            : null,
        actions: [
          if (_step == 0)
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Next'),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Step indicator ────────────────────────────────────────────
          _StepDots(current: _step, total: 2),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_date)),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),

                if (_step == 0) ...[
                  // ── Step 1: Mood ──────────────────────────────────────
                  if (settings.isModuleEnabled('happiness')) ...[
                    _Section(
                      title: 'How happy did you feel today? (0 – 10)',
                      child: _HappinessSlider(
                        value: _happinessScore,
                        onChanged: (v) => setState(() => _happinessScore = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (settings.isModuleEnabled('emotions')) ...[
                    _Section(
                      title: 'How are you feeling?',
                      child: EmotionTagSelector(
                        selected: _emotions,
                        onChanged: (v) => setState(() => _emotions = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (settings.isModuleEnabled('sleep')) ...[
                    _Section(
                      title: 'Overall, how well-rested did you feel with your sleep last night? (0 – 10)',
                      child: _HappinessSlider(
                        value: _sleepScore,
                        onChanged: (v) => setState(() => _sleepScore = v),
                        labelLow: '🪫',
                        labelHigh: '🔋',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _step = 1),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue'),
                    ),
                  ),
                ] else ...[
                  // ── Step 2: Lifestyle ─────────────────────────────────
                  if (settings.isModuleEnabled('activity')) ...[
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
                    const SizedBox(height: 16),
                  ],
                  if (settings.isModuleEnabled('food')) ...[
                    _Section(
                      title: 'What did you eat today?',
                      child: _ChipSelector(
                        options: const [
                          '🌾 Gluten',
                          '🥛 Lactose',
                          '🍬 Sugars',
                          '🍗 Chicken',
                          '🐟 Fish',
                        ],
                        selected: _foods,
                        onChanged: (v) => setState(() => _foods = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isFemale && settings.isModuleEnabled('symptoms')) ...[
                    _Section(
                      title: 'Symptoms',
                      child: SymptomSelector(
                        selected: _symptoms,
                        onChanged: (v) => setState(() => _symptoms = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (settings.isModuleEnabled('notes'))
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
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step dots indicator ───────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? primary : primary.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ── Happiness slider ──────────────────────────────────────────────────────────

class _HappinessSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String labelLow;
  final String labelHigh;

  const _HappinessSlider({
    required this.value,
    required this.onChanged,
    this.labelLow = '0',
    this.labelHigh = '10',
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Text(labelLow, style: const TextStyle(fontSize: 16)),
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
        Text(labelHigh, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
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
