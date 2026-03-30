import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/entry.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cycle_service.dart';
import '../widgets/cycle_phase_selector.dart';
import '../widgets/emotion_tag_selector.dart';
import 'log_entry_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isFemale =
        context.watch<SettingsProvider>().settings.isFemaleMode;

    // Male users only get the mood tab
    if (!isFemale) {
      return const _MoodCalendarTab();
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(icon: Icon(Icons.favorite_outline), text: 'Cycle'),
              Tab(icon: Icon(Icons.mood), text: 'Mood'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _CycleCalendarTab(),
                _MoodCalendarTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Opens LogEntryScreen for [dateStr] (past/today only).
void _openEntry(BuildContext context, String dateStr) {
  final entries = context.read<EntriesProvider>().entries;
  final existing = entries.cast<dynamic>().firstWhere(
        (e) => e.date == dateStr,
        orElse: () => null,
      );
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => LogEntryScreen(existing: existing, date: dateStr),
    ),
  );
}

// ── Cycle calendar tab ─────────────────────────────────────────────────────────

class _CycleCalendarTab extends StatefulWidget {
  const _CycleCalendarTab();

  @override
  State<_CycleCalendarTab> createState() => _CycleCalendarTabState();
}

class _CycleCalendarTabState extends State<_CycleCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, String> _phases = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshPhases();
  }

  void _refreshPhases() {
    final lastPeriodStart =
        context.read<SettingsProvider>().settings.lastPeriodStart;
    if (lastPeriodStart == null) {
      setState(() => _phases = {});
      return;
    }
    final entries = context.read<EntriesProvider>().entries;
    final rangeStart =
        DateTime(_focusedDay.year, _focusedDay.month - 2, 1);
    final rangeEnd =
        DateTime(_focusedDay.year, _focusedDay.month + 3, 0);
    setState(() {
      _phases = CycleService.predictPhases(
        lastPeriodStart: DateTime.parse(lastPeriodStart),
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        entries: entries,
      );
    });
  }

  Future<void> _showSetupSheet() async {
    DateTime? pickedStart;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SetupSheet(
        onSave: (date) async {
          pickedStart = date;
          Navigator.pop(ctx);
        },
      ),
    );
    if (pickedStart != null && mounted) {
      await context
          .read<SettingsProvider>()
          .setPeriodBaseline(DateFormat('yyyy-MM-dd').format(pickedStart!));
      _refreshPhases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final entries = context.watch<EntriesProvider>().entries;

    return Column(
      children: [
        // Setup banner when no baseline set
        if (settings.lastPeriodStart == null)
          _SetupBanner(onTap: _showSetupSheet),

        _SharedCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) {
            _focusedDay = focused;
            _refreshPhases();
          },
          entries: entries,
          dayColorBuilder: (day) {
            final phase = _phases[_dateOnly(day)];
            return phase != null
                ? cyclePhaseColor(phase)?.withAlpha(95)
                : null;
          },
        ),

        // Period logging panel for selected day
        if (_selectedDay != null &&
            !_selectedDay!.isAfter(DateTime.now())) ...[
          const Divider(height: 1),
          _PeriodDayPanel(
            day: _selectedDay!,
            entry: entries.cast<dynamic>().firstWhere(
                  (e) => e.date ==
                      DateFormat('yyyy-MM-dd').format(_selectedDay!),
                  orElse: () => null,
                ),
            onChanged: (periodStart, periodEnd) async {
              final dateStr =
                  DateFormat('yyyy-MM-dd').format(_selectedDay!);
              final existing = context
                  .read<EntriesProvider>()
                  .getByDate(dateStr);
              final updated = Entry.create(
                date: dateStr,
                emotions: existing?.emotions ?? [],
                cyclePhase: existing?.cyclePhase,
                periodStart: periodStart,
                periodEnd: periodEnd,
                symptoms: existing?.symptoms ?? [],
                happinessScore: existing?.happinessScore,
                foods: existing?.foods ?? [],
                activities: existing?.activities ?? [],
                notes: existing?.notes ?? '',
              );
              await context.read<EntriesProvider>().saveEntry(updated);
              _refreshPhases();
            },
          ),
        ],

        // Phase legend
        if (settings.lastPeriodStart != null) ...[
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _PhaseLegend(),
          ),
        ],
      ],
    );
  }
}

// ── Mood calendar tab ──────────────────────────────────────────────────────────

/// Blue → grey (3.5) → yellow (8) → warm gold (10)
Color _happinessColor(int score) {
  const blue   = Color(0xFF5C9BD6);
  const grey   = Color(0xFFB0BEC5);
  const yellow = Color(0xFFFDD835);
  const gold   = Color(0xFFFEC428);

  final t = score.clamp(0, 10) / 10.0;
  if (t <= 0.35) {
    return Color.lerp(blue,   grey,   t / 0.35)!;
  } else if (t <= 0.8) {
    return Color.lerp(grey,   yellow, (t - 0.35) / 0.45)!;
  } else {
    return Color.lerp(yellow, gold,   (t - 0.8)  / 0.20)!;
  }
}

class _MoodCalendarTab extends StatefulWidget {
  const _MoodCalendarTab();

  @override
  State<_MoodCalendarTab> createState() => _MoodCalendarTabState();
}

class _MoodCalendarTabState extends State<_MoodCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // null = happiness mode; an emotion value = filter to that emotion
  String? _filterEmotion;

  Color? _colorForDay(DateTime day, List<dynamic> entries) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    try {
      final entry = entries.firstWhere((e) => e.date == dateStr);
      if (_filterEmotion == null) {
        // Happiness mode: color by score, no color if not rated
        return entry.happinessScore != null
            ? _happinessColor(entry.happinessScore as int)
            : null;
      } else {
        // Emotion filter mode: full color if selected, faint grey if not
        return (entry.emotions as List).contains(_filterEmotion)
            ? emotionColor(_filterEmotion!)
            : Colors.grey.withAlpha(40);
      }
    } catch (_) {
      return null; // no entry for this day
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>().entries;

    return Column(
      children: [
        _SharedCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
            if (!selected.isAfter(DateTime.now())) {
              _openEntry(context, DateFormat('yyyy-MM-dd').format(selected));
            }
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
          entries: entries,
          dayColorBuilder: (day) => _colorForDay(day, entries),
        ),

        // Interactive legend
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _InteractiveMoodLegend(
            selectedEmotion: _filterEmotion,
            onSelected: (value) =>
                setState(() => _filterEmotion = value),
          ),
        ),
      ],
    );
  }
}

// ── Shared calendar widget ─────────────────────────────────────────────────────

class _SharedCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;
  final List<dynamic> entries;
  // Returns the background color for a day, or null for default.
  final Color? Function(DateTime day) dayColorBuilder;

  const _SharedCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.entries,
    required this.dayColorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: (day) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        return entries.any((e) => e.date == dateStr) ? ['logged'] : [];
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (_, day, __) => _DayCell(
            day: day, color: dayColorBuilder(day)),
        todayBuilder: (_, day, __) => _DayCell(
            day: day, color: dayColorBuilder(day), isToday: true),
        selectedBuilder: (_, day, __) => _DayCell(
            day: day, color: dayColorBuilder(day), isSelected: true),
        markerBuilder: (_, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          return Positioned(
            bottom: 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false),
    );
  }
}

// ── Day cell ───────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color? color;
  final bool isToday;
  final bool isSelected;

  const _DayCell({
    required this.day,
    this.color,
    this.isToday = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: color ?? primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        color: color ?? primary.withAlpha(60),
        shape: BoxShape.circle,
        border: Border.all(color: primary, width: 2),
      );
    } else if (color != null) {
      decoration = BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      );
    } else {
      decoration = const BoxDecoration(shape: BoxShape.circle);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: decoration,
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? Colors.white
                : color != null
                    ? (color!.computeLuminance() < 0.35
                        ? Colors.white
                        : Colors.black87)
                    : null,
            fontWeight: isToday || isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

// ── Legends ────────────────────────────────────────────────────────────────────

class _PhaseLegend extends StatelessWidget {
  const _PhaseLegend();

  @override
  Widget build(BuildContext context) {
    const phases = [
      ('Menstruation', 'menstruation'),
      ('Follicular', 'follicular'),
      ('Ovulation', 'ovulation'),
      ('Luteal', 'luteal'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: phases.map((p) => _LegendDot(p.$1, cyclePhaseColor(p.$2))).toList(),
    );
  }
}

/// Interactive legend for the mood calendar.
/// Shows a happiness gradient chip (default) and one chip per emotion.
/// Tapping an emotion chip filters the calendar to days where it was logged.
/// Tapping it again (or tapping the happiness chip) returns to default.
class _InteractiveMoodLegend extends StatelessWidget {
  final String? selectedEmotion; // null = happiness mode
  final ValueChanged<String?> onSelected;

  const _InteractiveMoodLegend({
    required this.selectedEmotion,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final happinessSelected = selectedEmotion == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Happiness gradient chip ──────────────────────────────────────
        GestureDetector(
          onTap: () => onSelected(null),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: happinessSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              color: happinessSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient strip
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 48,
                    height: 10,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5C9BD6), // blue   = 0
                            Color(0xFFB0BEC5), // grey   ≈ 3.5
                            Color(0xFFFDD835), // yellow = 8
                            Color(0xFFFEC428), // gold   = 10
                          ],
                          stops: [0.0, 0.35, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Happiness', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Emotion filter chips ─────────────────────────────────────────
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: emotions.map((e) {
            final isSelected = selectedEmotion == e.value;
            return GestureDetector(
              onTap: () =>
                  onSelected(isSelected ? null : e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? e.color.withAlpha(200)
                      : e.color.withAlpha(50),
                  border: Border.all(
                    color: isSelected ? e.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: e.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      e.label.split(' ').last,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Period day panel ───────────────────────────────────────────────────────────

class _PeriodDayPanel extends StatelessWidget {
  final DateTime day;
  final dynamic entry; // Entry? — untyped to avoid import issues at call site
  final void Function(bool periodStart, bool periodEnd) onChanged;

  const _PeriodDayPanel({
    required this.day,
    required this.entry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool periodStart = (entry?.periodStart as bool?) ?? false;
    final bool periodEnd = (entry?.periodEnd as bool?) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          SwitchListTile(
            title: const Text('Period started on this day'),
            value: periodStart,
            onChanged: (v) => onChanged(v, periodEnd),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Period ended on this day'),
            value: periodEnd,
            onChanged: (v) => onChanged(periodStart, v),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ── Setup banner ───────────────────────────────────────────────────────────────

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap to set your last period start date and see cycle predictions.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Setup bottom sheet ─────────────────────────────────────────────────────────

class _SetupSheet extends StatefulWidget {
  final Future<void> Function(DateTime) onSave;
  const _SetupSheet({required this.onSave});

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  DateTime? _startDate;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'When did your last period start?',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set up cycle tracking',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
              'Enter the start date of your last period. '
              'sarAPP will predict your current phase using a 28-day cycle average. '
              'Predictions will improve as you log more data.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(_startDate == null
                ? 'Pick start date'
                : DateFormat('MMMM d, yyyy').format(_startDate!)),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                _startDate == null ? null : () => widget.onSave(_startDate!),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
