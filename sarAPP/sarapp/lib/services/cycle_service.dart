import '../models/entry.dart';

/// Predicts menstrual cycle phases from a baseline date.
///
/// Defaults (no logged data):
///   28-day cycle, 5-day period.
///
/// When [entries] are provided, personal averages are calculated:
///   - cycleLength  = mean gap between consecutive period-start entries
///   - periodLength = mean duration between a period-start and the next period-end
class CycleService {
  static const int _defaultCycleLength = 28;
  static const int _defaultPeriodLength = 5;

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ── Personal stats ──────────────────────────────────────────────────────────

  /// Derives personal cycle and period lengths from logged entries.
  /// Falls back to defaults when there is insufficient data.
  static ({int cycleLength, int periodLength}) cycleStats(
      List<Entry> entries) {
    // --- cycle length: gaps between consecutive period starts ---
    final starts = entries
        .where((e) => e.periodStart)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    int cycleLength = _defaultCycleLength;
    if (starts.length >= 2) {
      int totalGap = 0;
      for (int i = 1; i < starts.length; i++) {
        totalGap += starts[i].difference(starts[i - 1]).inDays;
      }
      cycleLength = (totalGap / (starts.length - 1)).round();
    }

    // --- period length: gap from each start to the nearest subsequent end ---
    final ends = entries
        .where((e) => e.periodEnd)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    int periodLength = _defaultPeriodLength;
    if (starts.isNotEmpty && ends.isNotEmpty) {
      final durations = <int>[];
      for (final s in starts) {
        // find earliest end on or after this start
        final end = ends.cast<DateTime?>().firstWhere(
              (e) => !e!.isBefore(s),
              orElse: () => null,
            );
        if (end != null) {
          durations.add(end.difference(s).inDays + 1);
        }
      }
      if (durations.isNotEmpty) {
        periodLength =
            (durations.reduce((a, b) => a + b) / durations.length).round();
      }
    }

    return (cycleLength: cycleLength, periodLength: periodLength);
  }

  // ── Phase mapping ───────────────────────────────────────────────────────────

  /// Phase name for a 0-based day index within a cycle of [cycleLength] days
  /// and [periodLength] days of menstruation.
  static String phaseForDayIndex(int index,
      {int cycleLength = _defaultCycleLength,
      int periodLength = _defaultPeriodLength}) {
    if (index < periodLength) return 'menstruation';
    // Ovulation is placed 14 days before the end of the cycle (luteal = 14d)
    final ovulationDay = cycleLength - 15; // 0-based
    if (index < ovulationDay) return 'follicular';
    if (index == ovulationDay) return 'ovulation';
    return 'luteal';
  }

  // ── Predictions ─────────────────────────────────────────────────────────────

  /// Returns a map of date → predicted phase for all days in
  /// [rangeStart]..[rangeEnd], optionally personalised from [entries].
  static Map<DateTime, String> predictPhases({
    required DateTime lastPeriodStart,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    List<Entry>? entries,
  }) {
    final stats = entries != null ? cycleStats(entries) : null;
    final cycleLength = stats?.cycleLength ?? _defaultCycleLength;
    final periodLength = stats?.periodLength ?? _defaultPeriodLength;

    final result = <DateTime, String>{};
    final start = _dateOnly(lastPeriodStart);
    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);

    final daysDiff = rs.difference(start).inDays;
    final cycleOffset = (daysDiff / cycleLength).floor() - 1;
    var cycleStart = start.add(Duration(days: cycleOffset * cycleLength));

    while (!cycleStart.isAfter(re)) {
      for (int i = 0; i < cycleLength; i++) {
        final date = _dateOnly(cycleStart.add(Duration(days: i)));
        if (!date.isBefore(rs) && !date.isAfter(re)) {
          result[date] = phaseForDayIndex(i,
              cycleLength: cycleLength, periodLength: periodLength);
        }
      }
      cycleStart = cycleStart.add(Duration(days: cycleLength));
    }

    return result;
  }

  /// The predicted phase for today, or null if no baseline is set.
  static String? todayPhase(String? lastPeriodStartStr,
      {List<Entry>? entries}) {
    if (lastPeriodStartStr == null) return null;
    final today = _dateOnly(DateTime.now());
    final phases = predictPhases(
      lastPeriodStart: DateTime.parse(lastPeriodStartStr),
      rangeStart: today,
      rangeEnd: today,
      entries: entries,
    );
    return phases[today];
  }

  /// Day number within the current cycle (1-based).
  static int dayOfCycle(String lastPeriodStartStr, {List<Entry>? entries}) {
    final stats = entries != null ? cycleStats(entries) : null;
    final cycleLength = stats?.cycleLength ?? _defaultCycleLength;
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(DateTime.parse(lastPeriodStartStr));
    final diff = today.difference(start).inDays;
    return (diff % cycleLength) + 1;
  }

  /// Days remaining until the next predicted period starts.
  static int daysUntilNextPeriod(String lastPeriodStartStr,
      {List<Entry>? entries}) {
    final stats = entries != null ? cycleStats(entries) : null;
    final cycleLength = stats?.cycleLength ?? _defaultCycleLength;
    final day = dayOfCycle(lastPeriodStartStr, entries: entries);
    return cycleLength - day + 1;
  }
}
