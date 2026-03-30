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
///   Days P+1..C-14         → follicular
///   Day  C-13              → ovulation
///   Days C-12..C           → luteal  (always 13 days + ovulation day = 14 days total)
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

    // --- cycle length: gaps between consecutive period starts ---
    int cycleLength = _defaultCycleLength;
    final int cyclesLogged = starts.length >= 2 ? starts.length - 1 : 0;
    if (cyclesLogged > 0) {
      int totalGap = 0;
      for (int i = 1; i < starts.length; i++) {
        totalGap += starts[i].difference(starts[i - 1]).inDays;
      }
      cycleLength = (totalGap / cyclesLogged).round();
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
      periodLength =
          (durations.reduce((a, b) => a + b) / periodsLogged).round();
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
  static String phaseForDayIndex(int index,
      {int cycleLength = _defaultCycleLength,
      int periodLength = _defaultPeriodLength}) {
    // Ovulation is at index (cycleLength - 14), i.e. 14 days before end of cycle
    final ovulationIndex = cycleLength - 14;
    if (index < periodLength) return 'menstruation';
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
              cycleLength: cycleLength, periodLength: periodLength);
        }
      }
      cycleStart = cycleStart.add(Duration(days: cycleLength));
    }
    return result;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Builds the complete phase map for a date range by:
  ///   1. Anchoring prediction to the most recent logged period start
  ///      (falls back to [baselinePeriodStart] from settings).
  ///   2. Using personal cycle/period lengths derived from [entries].
  ///   3. Overwriting prediction with actual menstruation for every logged
  ///      periodStart → periodEnd span.
  static Map<DateTime, String> buildPhaseMap({
    required String? baselinePeriodStart,
    required List<Entry> entries,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final stats = cycleStats(entries);
    final loggedStarts = entries
        .where((e) => e.periodStart)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    // Best anchor = most recent logged period start, else settings baseline
    final DateTime? anchor = loggedStarts.isNotEmpty
        ? loggedStarts.last
        : (baselinePeriodStart != null
            ? _dateOnly(DateTime.parse(baselinePeriodStart))
            : null);

    if (anchor == null) return {};

    // Step 1: predict
    final phases = _predictFromAnchor(
      anchor: anchor,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      cycleLength: stats.cycleLength,
      periodLength: stats.periodLength,
    );

    // Step 2: overwrite with actual logged menstruation spans
    final loggedEnds = entries
        .where((e) => e.periodEnd)
        .map((e) => _dateOnly(DateTime.parse(e.date)))
        .toList()
      ..sort();

    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);

    for (final start in loggedStarts) {
      final end = loggedEnds.cast<DateTime?>().firstWhere(
            (e) => !e!.isBefore(start),
            orElse: () => null,
          ) ??
          start.add(Duration(days: stats.periodLength - 1));

      var day = start;
      while (!day.isAfter(end)) {
        if (!day.isBefore(rs) && !day.isAfter(re)) {
          phases[day] = 'menstruation';
        }
        day = day.add(const Duration(days: 1));
      }
    }

    return phases;
  }

  /// The predicted phase for today.
  static String? todayPhase(String? baselinePeriodStart,
      {List<Entry>? entries}) {
    final today = _dateOnly(DateTime.now());
    final map = buildPhaseMap(
      baselinePeriodStart: baselinePeriodStart,
      entries: entries ?? [],
      rangeStart: today,
      rangeEnd: today,
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
