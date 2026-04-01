import '../models/entry.dart';

/// Menstrual cycle phase prediction with personalised stats.
///
/// Scientific basis:
///   - Luteal phase is ~14 days in most women (constant).
///   - Ovulation is 1 day, ~14 days before next period (day cycleLength-13, 1-based).
///   - Follicular = everything between end of menstruation and ovulation (variable).
///   - Menstruation length is personal and derived from logged periodStart/End data.
///
/// Phase layout (1-based day of cycle, given cycleLength C and periodLength P):
///   Days 1..P              → menstruation
///   Days P+1..C-15         → follicular        (variable)
///   Days C-14..C-1  [opt]  → fertile window    (5 days ending on ovulation)
///   Day  C-14              → ovulation         (or absorbed into fertile window)
///   Days C-13..C           → luteal            (always 14 days)
class CycleService {
  static const int _defaultCycleLength = 28;
  static const int _defaultPeriodLength = 5;

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  // ── Personal stats ──────────────────────────────────────────────────────────

  /// Derives personal cycle and period lengths from logged entries.
  /// Returns defaults when there is insufficient data.
  static ({int cycleLength, int periodLength, int cyclesLogged, int periodsLogged})
      cycleStats(List<Entry> entries) {
    // --- period starts (sorted) ---
    final starts = entries
        .where((e) => e.periodStart)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    // --- cycle length: median gap between consecutive period starts ---
    int cycleLength = _defaultCycleLength;
    final int cyclesLogged = starts.length >= 2 ? starts.length - 1 : 0;
    if (cyclesLogged > 0) {
      final gaps = <int>[];
      for (int i = 1; i < starts.length; i++) {
        gaps.add(starts[i].difference(starts[i - 1]).inDays);
      }
      gaps.sort();
      cycleLength = gaps.length.isOdd
          ? gaps[gaps.length ~/ 2]
          : ((gaps[gaps.length ~/ 2 - 1] + gaps[gaps.length ~/ 2]) / 2)
              .round();
    }

    // --- period length: start → nearest subsequent end ---
    final ends = entries
        .where((e) => e.periodEnd)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    int periodLength = _defaultPeriodLength;
    final durations = <int>[];
    for (final s in starts) {
      final end = ends.cast<DateTime?>().firstWhere(
            (e) => !e!.isBefore(s),
            orElse: () => null,
          );
      if (end != null) {
        durations.add(end.difference(s).inDays + 1);
      }
    }
    final periodsLogged = durations.length;
    if (periodsLogged > 0) {
      final sorted = [...durations]..sort();
      periodLength = sorted.length.isOdd
          ? sorted[sorted.length ~/ 2]
          : ((sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2)
              .round();
    }

    // Safety: luteal is always 14 days; cycleLength must be at least periodLength + 15
    if (cycleLength < periodLength + 15) {
      cycleLength = periodLength + 15;
    }

    return (
      cycleLength: cycleLength,
      periodLength: periodLength,
      cyclesLogged: cyclesLogged,
      periodsLogged: periodsLogged,
    );
  }

  // ── Phase mapping ───────────────────────────────────────────────────────────

  /// Phase name for a 0-based day index within a cycle.
  ///
  /// [showHighFertility] replaces the single ovulation day with a 5-day
  /// higher-fertility window (4 days pre-ovulation + ovulation day).
  static String phaseForDayIndex(
    int index, {
    int cycleLength = _defaultCycleLength,
    int periodLength = _defaultPeriodLength,
    bool showHighFertility = false,
  }) {
    // Ovulation at index cycleLength-15 (0-based) = day cycleLength-14 (1-based).
    // Luteal then spans indices cycleLength-14 .. cycleLength-1 = 14 days.
    final ovulationIndex = cycleLength - 15;
    final fertileStart = ovulationIndex - 4; // 5-day window ending on ovulation
    if (index < periodLength) return 'menstruation';
    if (showHighFertility && index >= fertileStart && index <= ovulationIndex) {
      return 'high_fertility';
    }
    if (index < ovulationIndex) return 'follicular';
    if (index == ovulationIndex) return 'ovulation';
    return 'luteal';
  }

  // ── Core prediction ─────────────────────────────────────────────────────────

  /// Predicts phases for [rangeStart]..[rangeEnd] from a single anchor date.
  static Map<DateTime, String> _predictFromAnchor({
    required DateTime anchor,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required int cycleLength,
    required int periodLength,
    bool showHighFertility = false,
  }) {
    final result = <DateTime, String>{};
    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);

    final daysDiff = rs.difference(anchor).inDays;
    final cycleOffset = (daysDiff / cycleLength).floor() - 1;
    var cycleStart = anchor.add(Duration(days: cycleOffset * cycleLength));

    while (!cycleStart.isAfter(re)) {
      for (int i = 0; i < cycleLength; i++) {
        final date = _dateOnly(cycleStart.add(Duration(days: i)));
        if (!date.isBefore(rs) && !date.isAfter(re)) {
          result[date] = phaseForDayIndex(i,
              cycleLength: cycleLength,
              periodLength: periodLength,
              showHighFertility: showHighFertility);
        }
      }
      cycleStart = cycleStart.add(Duration(days: cycleLength));
    }
    return result;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Builds the complete phase map for a date range.
  ///
  /// Strategy:
  ///   - Before the first ever logged period start → nothing shown (no backward
  ///     extrapolation, so no phantom period starts in the past).
  ///   - Between two consecutive logged period starts → phases predicted from
  ///     the *earlier* start as anchor (each past cycle uses its own real start).
  ///   - From the most recent logged period start onward → predicted forward,
  ///     cycling around with modular day index for multi-cycle future display.
  ///   - Falls back to [baselinePeriodStart] only when nothing has been logged.
  ///   - Actual logged menstruation spans always overwrite predictions.
  static Map<DateTime, String> buildPhaseMap({
    required String? baselinePeriodStart,
    required List<Entry> entries,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool showHighFertility = false,
  }) {
    final stats = cycleStats(entries);
    final phases = <DateTime, String>{};
    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);

    final loggedStarts = entries
        .where((e) => e.periodStart)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    final loggedEnds = entries
        .where((e) => e.periodEnd)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    if (loggedStarts.isEmpty) {
      // No logged data at all — fall back to pure prediction from baseline.
      final anchor = baselinePeriodStart != null
          ? _dateOnly(DateTime.parse(baselinePeriodStart))
          : null;
      if (anchor == null) return {};
      phases.addAll(_predictFromAnchor(
        anchor: anchor,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        cycleLength: stats.cycleLength,
        periodLength: stats.periodLength,
        showHighFertility: showHighFertility,
      ));
    } else {
      // One segment per logged period start.
      for (int i = 0; i < loggedStarts.length; i++) {
        final segAnchor = loggedStarts[i];
        // Segment ends the day before the next logged start, or at rangeEnd
        // for the most recent start (which predicts forward).
        final segEnd = i < loggedStarts.length - 1
            ? _dateOnly(loggedStarts[i + 1].subtract(const Duration(days: 1)))
            : re;

        for (int d = 0; ; d++) {
          final date = _dateOnly(segAnchor.add(Duration(days: d)));
          if (date.isAfter(segEnd)) break;
          if (!date.isBefore(rs) && !date.isAfter(re)) {
            // Wrap day index only for the last (future-predicting) segment so
            // multiple upcoming cycles get correct phase labels.
            final index =
                i < loggedStarts.length - 1 ? d : d % stats.cycleLength;
            phases[date] = phaseForDayIndex(index,
                cycleLength: stats.cycleLength,
                periodLength: stats.periodLength,
                showHighFertility: showHighFertility);
          }
        }
      }
    }

    // Overwrite with actual logged menstruation spans.
    for (final start in loggedStarts) {
      final end = loggedEnds.cast<DateTime?>().firstWhere(
            (e) => !e!.isBefore(start),
            orElse: () => null,
          ) ??
          _dateOnly(start.add(Duration(days: stats.periodLength - 1)));

      var day = _dateOnly(start);
      while (!day.isAfter(end)) {
        if (!day.isBefore(rs) && !day.isAfter(re)) {
          phases[day] = 'menstruation';
        }
        day = _dateOnly(day.add(const Duration(days: 1)));
      }
    }

    return phases;
  }

  /// The predicted phase for today.
  static String? todayPhase(String? baselinePeriodStart,
      {List<Entry>? entries, bool showHighFertility = false}) {
    final today = _dateOnly(DateTime.now());
    final map = buildPhaseMap(
      baselinePeriodStart: baselinePeriodStart,
      entries: entries ?? [],
      rangeStart: today,
      rangeEnd: today,
      showHighFertility: showHighFertility,
    );
    return map[today];
  }

  /// Day number within the current cycle (1-based).
  static int dayOfCycle(String baselinePeriodStart,
      {List<Entry>? entries}) {
    final stats = cycleStats(entries ?? []);
    final allStarts = (entries ?? [])
        .where((e) => e.periodStart)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    final anchor = allStarts.isNotEmpty
        ? allStarts.last
        : _dateOnly(DateTime.parse(baselinePeriodStart));

    final today = _dateOnly(DateTime.now());
    final diff = today.difference(anchor).inDays;
    return (diff % stats.cycleLength) + 1;
  }

  /// Days remaining until the next predicted period starts.
  static int daysUntilNextPeriod(String baselinePeriodStart,
      {List<Entry>? entries}) {
    final stats = cycleStats(entries ?? []);
    final day = dayOfCycle(baselinePeriodStart, entries: entries);
    return stats.cycleLength - day + 1;
  }
}
