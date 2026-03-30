/// Predicts menstrual cycle phases from a baseline date using average values.
///
/// Average 28-day cycle breakdown (1-indexed day of cycle):
///   Days  1– 5  →  Menstruation  (5 days)
///   Days  6–13  →  Follicular    (8 days)
///   Day  14     →  Ovulation     (1 day)
///   Days 15–28  →  Luteal        (14 days)
class CycleService {
  static const int avgCycleLength = 28;
  static const int avgPeriodLength = 5;

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Phase name for a 0-based day index within the cycle.
  static String phaseForDayIndex(int index) {
    if (index < avgPeriodLength) return 'menstruation';
    if (index < 13) return 'follicular';
    if (index == 13) return 'ovulation';
    return 'luteal';
  }

  /// Returns a map of date → predicted phase for all days in [rangeStart]..[rangeEnd].
  static Map<DateTime, String> predictPhases({
    required DateTime lastPeriodStart,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final result = <DateTime, String>{};
    final start = _dateOnly(lastPeriodStart);
    final rs = _dateOnly(rangeStart);
    final re = _dateOnly(rangeEnd);

    // Find a cycle start safely before rangeStart
    final daysDiff = rs.difference(start).inDays;
    final cycleOffset = (daysDiff / avgCycleLength).floor() - 1;
    var cycleStart = start.add(Duration(days: cycleOffset * avgCycleLength));

    while (!cycleStart.isAfter(re)) {
      for (int i = 0; i < avgCycleLength; i++) {
        final date = _dateOnly(cycleStart.add(Duration(days: i)));
        if (!date.isBefore(rs) && !date.isAfter(re)) {
          result[date] = phaseForDayIndex(i);
        }
      }
      cycleStart = cycleStart.add(Duration(days: avgCycleLength));
    }

    return result;
  }

  /// The predicted phase for today, or null if no baseline is set.
  static String? todayPhase(String? lastPeriodStartStr) {
    if (lastPeriodStartStr == null) return null;
    final today = _dateOnly(DateTime.now());
    final phases = predictPhases(
      lastPeriodStart: DateTime.parse(lastPeriodStartStr),
      rangeStart: today,
      rangeEnd: today,
    );
    return phases[today];
  }

  /// Day number within the current cycle (1-based), e.g. "Day 14".
  static int dayOfCycle(String lastPeriodStartStr) {
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(DateTime.parse(lastPeriodStartStr));
    final diff = today.difference(start).inDays;
    return (diff % avgCycleLength) + 1;
  }

  /// Days remaining until the next predicted period starts.
  static int daysUntilNextPeriod(String lastPeriodStartStr) {
    final day = dayOfCycle(lastPeriodStartStr);
    return avgCycleLength - day + 1;
  }
}
