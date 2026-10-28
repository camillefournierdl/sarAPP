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
import '../l10n/l10n_helpers.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  void _onFocusedDayChanged(DateTime day) =>
      setState(() => _focusedDay = day);

  void _jumpToToday() =>
      setState(() => _focusedDay = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final isFemale =
        context.watch<SettingsProvider>().settings.isMenstruationTracking;

    final todayButton = IconButton(
      icon: const Icon(Icons.today),
      tooltip: context.l10n.goToToday,
      onPressed: _jumpToToday,
    );

    // Male users only get the mood tab
    if (!isFemale) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: todayButton,
          ),
          Expanded(
            child: _MoodCalendarTab(
              focusedDay: _focusedDay,
              onFocusedDayChanged: _onFocusedDayChanged,
            ),
          ),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  tabs: [
                    Tab(
                        icon: const Icon(Icons.favorite_outline),
                        text: context.l10n.tabCycle),
                    Tab(icon: const Icon(Icons.mood), text: context.l10n.tabMood),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              // Cycle-phase help, only on the Cycle tab. maintainSize keeps
              // the TabBar width stable when switching tabs.
              Builder(builder: (context) {
                final controller = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Visibility(
                    visible: controller.index == 0,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: context.l10n.aboutCyclePhases,
                      onPressed: () => _showCycleInfo(context),
                    ),
                  ),
                );
              }),
              todayButton,
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CycleCalendarTab(
                  focusedDay: _focusedDay,
                  onFocusedDayChanged: _onFocusedDayChanged,
                ),
                _MoodCalendarTab(
                  focusedDay: _focusedDay,
                  onFocusedDayChanged: _onFocusedDayChanged,
                ),
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
  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocusedDayChanged;
  const _CycleCalendarTab(
      {required this.focusedDay, required this.onFocusedDayChanged});

  @override
  State<_CycleCalendarTab> createState() => _CycleCalendarTabState();
}

class _CycleCalendarTabState extends State<_CycleCalendarTab> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>().entries;
    final settings = context.watch<SettingsProvider>().settings;
    final hasPeriodEntries = entries.any((e) => e.periodStart);

    // Compute phases here so any change to entries, settings, or focusedDay
    // automatically produces the correct map without manual refresh calls.
    final rangeStart =
        DateTime(widget.focusedDay.year, widget.focusedDay.month - 2, 1);
    final rangeEnd =
        DateTime(widget.focusedDay.year, widget.focusedDay.month + 3, 0);
    final phases =
        (settings.lastPeriodStart != null || hasPeriodEntries)
            ? CycleService.buildPhaseMap(
                baselinePeriodStart: settings.lastPeriodStart,
                entries: entries,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                showHighFertility: settings.showHighFertility,
              )
            : <DateTime, String>{};

    // Content-based key so TableCalendar fully recreates when phases change.
    // Without this, TableCalendar (a StatefulWidget) may not re-render its
    // day cells when only the builder callbacks are updated.
    final phasesKey = ValueKey(Object.hashAll(
      phases.entries.map((e) => Object.hash(e.key, e.value)),
    ));

    final sexDates = settings.showLastSex
        ? entries
            .where((e) => e.hadSex?.toLowerCase() == 'yes')
            .map<String>((e) => e.date as String)
            .toSet()
        : <String>{};

    return SingleChildScrollView(
      child: Column(
        children: [
        // Instruction when no period data logged yet
        if (!hasPeriodEntries)
          _InstructionBanner(
            message: context.l10n.cycleCalendarHint,
          ),

        _SharedCalendar(
          key: phasesKey,
          focusedDay: widget.focusedDay,
          selectedDay: _selectedDay,
          onDaySelected: (selected, focused) {
            setState(() => _selectedDay = selected);
            widget.onFocusedDayChanged(focused);
          },
          onPageChanged: widget.onFocusedDayChanged,
          entries: entries,
          sexDates: sexDates,
          dayColorBuilder: (day) {
            final phase = phases[_dateOnly(day)];
            return phase != null
                ? cyclePhaseColor(phase).withAlpha(95)
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
              final updated = existing != null
                  ? existing.copyWith(
                      periodStart: periodStart, periodEnd: periodEnd)
                  : Entry.create(
                      date: dateStr,
                      periodStart: periodStart,
                      periodEnd: periodEnd,
                    );
              await context.read<EntriesProvider>().saveEntry(updated);
            },
          ),
        ],

        // Phase legend — shown only when there is phase data
        if (phases.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _PhaseLegend(
              showHighFertility: settings.showHighFertility,
              showLastSex: settings.showLastSex,
            ),
          ),
        ],
      ],
      ),
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
  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocusedDayChanged;
  const _MoodCalendarTab(
      {required this.focusedDay, required this.onFocusedDayChanged});

  @override
  State<_MoodCalendarTab> createState() => _MoodCalendarTabState();
}

class _MoodCalendarTabState extends State<_MoodCalendarTab> {
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
        // Emotion filter mode: full color if selected, faint grey if not.
        // Entries may store either the short key ('angry') or the display
        // label ('😤 Angry') depending on when they were logged, so check both.
        final emotions = entry.emotions as List;
        final matches = emotions.contains(_filterEmotion) ||
            emotions.contains(emotionLabel(_filterEmotion!));
        return matches
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

    return SingleChildScrollView(
      child: Column(
        children: [
          _InstructionBanner(
            message: context.l10n.moodCalendarHint,
          ),

          _SharedCalendar(
            focusedDay: widget.focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected, focused) {
              setState(() => _selectedDay = selected);
              widget.onFocusedDayChanged(focused);
              if (!selected.isAfter(DateTime.now())) {
                _openEntry(context, DateFormat('yyyy-MM-dd').format(selected));
              }
            },
            onPageChanged: (focused) => widget.onFocusedDayChanged(focused),
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
      ),
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
  final Color? Function(DateTime day) dayColorBuilder;
  final Set<String> sexDates;

  const _SharedCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.entries,
    required this.dayColorBuilder,
    this.sexDates = const {},
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: Localizations.localeOf(context).toLanguageTag(),
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      startingDayOfWeek: _resolveStartDay(context),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: (day) {
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final entry = entries.cast<dynamic>().firstWhere(
              (e) => e.date == dateStr,
              orElse: () => null,
            );
        return (entry != null && entry.hasData) ? ['logged'] : [];
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (_, day, __) => _DayCell(
            day: day,
            color: dayColorBuilder(day),
            hasSex: sexDates.contains(DateFormat('yyyy-MM-dd').format(day))),
        todayBuilder: (_, day, __) => _DayCell(
            day: day,
            color: dayColorBuilder(day),
            isToday: true,
            hasSex: sexDates.contains(DateFormat('yyyy-MM-dd').format(day))),
        selectedBuilder: (_, day, __) => _DayCell(
            day: day,
            color: dayColorBuilder(day),
            isSelected: true,
            hasSex: sexDates.contains(DateFormat('yyyy-MM-dd').format(day))),
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
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextFormatter: (date, locale) =>
            DateFormat.yMMMM(locale).format(date).toLowerCase(),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        dowTextFormatter: (date, locale) =>
            DateFormat.E(locale).format(date).toLowerCase(),
      ),
    );
  }
}

// ── Week start helpers ────────────────────────────────────────────────────────

StartingDayOfWeek _resolveStartDay(BuildContext context) {
  final pref = context.read<SettingsProvider>().settings.calendarStartDay;
  return pref == 'sunday' ? StartingDayOfWeek.sunday : StartingDayOfWeek.monday;
}

// ── Day cell ───────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Color? color;
  final bool isToday;
  final bool isSelected;
  final bool hasSex;

  const _DayCell({
    required this.day,
    this.color,
    this.isToday = false,
    this.isSelected = false,
    this.hasSex = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: color ?? primary.withAlpha(60),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2.5),
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

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: decoration,
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: isSelected ? 14 : 13,
                color: isSelected
                    ? Colors.black
                    : color != null
                        ? (color!.computeLuminance() < 0.35
                            ? Colors.white
                            : Colors.black87)
                        : null,
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
        if (hasSex)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E8C),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Legends ────────────────────────────────────────────────────────────────────

class _PhaseLegend extends StatelessWidget {
  final bool showHighFertility;
  final bool showLastSex;
  const _PhaseLegend({required this.showHighFertility, this.showLastSex = false});

  @override
  Widget build(BuildContext context) {
    final phases = [
      'menstruation',
      'follicular',
      if (showHighFertility) 'high_fertility' else 'ovulation',
      'luteal',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        ...phases.map((p) =>
            _LegendDot(context.l10n.cyclePhase(p), cyclePhaseColor(p))),
        if (showLastSex)
          _LegendDot(context.l10n.intimacy, const Color(0xFFE91E8C)),
      ],
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
                Text(context.l10n.modHappiness,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Emotion filter chips ─────────────────────────────────────────
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: builtInEmotions.map((e) {
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
                      context.l10n.option(e.label).split(' ').last,
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
            DateFormat.MMMMEEEEd().format(day).toLowerCase(),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          SwitchListTile(
            title: Text(context.l10n.periodStartedToday),
            value: periodStart,
            onChanged: (v) => onChanged(v, periodEnd),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          SwitchListTile(
            title: Text(context.l10n.periodEndedToday),
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

// ── Instruction banner ─────────────────────────────────────────────────────────

// ── Cycle info sheet ───────────────────────────────────────────────────────────

void _showCycleInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) =>
          _CycleInfoSheet(scrollController: scrollController),
    ),
  );
}

class _CycleInfoSheet extends StatelessWidget {
  final ScrollController scrollController;
  const _CycleInfoSheet({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final l10n = context.l10n;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(l10n.cycleInfoTitle,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          l10n.cycleInfoIntro,
          style: muted,
        ),
        const SizedBox(height: 20),
        _PhaseInfo(
          phase: 'menstruation',
          title: l10n.phaseInfoMenstruationTitle,
          duration: l10n.phaseInfoMenstruationDuration,
          body: l10n.phaseInfoMenstruationBody,
        ),
        _PhaseInfo(
          phase: 'follicular',
          title: l10n.phaseInfoFollicularTitle,
          duration: l10n.phaseInfoFollicularDuration,
          body: l10n.phaseInfoFollicularBody,
        ),
        _PhaseInfo(
          phase: 'high_fertility',
          title: l10n.phaseInfoFertilityTitle,
          duration: l10n.phaseInfoFertilityDuration,
          body: l10n.phaseInfoFertilityBody,
        ),
        _PhaseInfo(
          phase: 'ovulation',
          title: l10n.phaseInfoOvulationTitle,
          duration: l10n.phaseInfoOvulationDuration,
          body: l10n.phaseInfoOvulationBody,
        ),
        _PhaseInfo(
          phase: 'luteal',
          title: l10n.phaseInfoLutealTitle,
          duration: l10n.phaseInfoLutealDuration,
          body: l10n.phaseInfoLutealBody,
        ),
        const SizedBox(height: 8),
        Text(l10n.everyBodyTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          l10n.everyBodyBody,
          style: muted,
        ),
        const SizedBox(height: 20),
        Text(l10n.knowYourCycleTitle,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          l10n.knowYourCycleBody,
          style: muted,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.phasesEstimateNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _PhaseInfo extends StatelessWidget {
  final String phase;
  final String title;
  final String duration;
  final String body;
  const _PhaseInfo({
    required this.phase,
    required this.title,
    required this.duration,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CircleAvatar(
              radius: 7,
              backgroundColor: cyclePhaseColor(phase),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(duration,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  final String message;
  const _InstructionBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
