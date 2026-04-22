import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/entry.dart';
import '../services/analytics_service.dart';

enum AnalyticsTimeWindow { allTime, lastMonth, last3Months, custom }

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsFocus? focus;
  AnalyticsTimeWindow timeWindow = AnalyticsTimeWindow.allTime;
  DateTimeRange? customRange;
  List<AssociationResult> results = [];
  bool isComputing = false;
  int entryCount = 0;

  Future<void> setFocus(
    AnalyticsFocus f,
    List<Entry> entries,
    AppSettings s,
  ) async {
    focus = f;
    await _recompute(entries, s);
  }

  Future<void> setTimeWindow(
    AnalyticsTimeWindow w,
    List<Entry> entries,
    AppSettings s, {
    DateTimeRange? range,
  }) async {
    timeWindow = w;
    if (w == AnalyticsTimeWindow.custom) customRange = range;
    if (focus != null) await _recompute(entries, s);
  }

  Future<void> _recompute(List<Entry> entries, AppSettings s) async {
    isComputing = true;
    notifyListeners();

    final (windowStart, windowEnd) = _windowDates();

    entryCount = entries.where((e) {
      final d = DateTime.parse(e.date);
      if (windowStart != null && d.isBefore(windowStart)) return false;
      if (windowEnd != null && d.isAfter(windowEnd)) return false;
      return true;
    }).length;

    results = await Future.microtask(
      () => AnalyticsService.computeAssociations(
        entries: entries,
        focus: focus!,
        settings: s,
        windowStart: windowStart,
        windowEnd: windowEnd,
      ),
    );

    isComputing = false;
    notifyListeners();
  }

  (DateTime?, DateTime?) _windowDates() => switch (timeWindow) {
        AnalyticsTimeWindow.allTime => (null, null),
        AnalyticsTimeWindow.lastMonth =>
          (DateTime.now().subtract(const Duration(days: 30)), null),
        AnalyticsTimeWindow.last3Months =>
          (DateTime.now().subtract(const Duration(days: 90)), null),
        AnalyticsTimeWindow.custom =>
          (customRange?.start, customRange?.end),
      };

  String windowLabel() => switch (timeWindow) {
        AnalyticsTimeWindow.allTime => 'all time',
        AnalyticsTimeWindow.lastMonth => 'last 30 days',
        AnalyticsTimeWindow.last3Months => 'last 3 months',
        AnalyticsTimeWindow.custom when customRange != null =>
          '${_fmt(customRange!.start)} – ${_fmt(customRange!.end)}',
        _ => 'custom range',
      };

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
