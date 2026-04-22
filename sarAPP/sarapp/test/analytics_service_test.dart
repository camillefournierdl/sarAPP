import 'package:flutter_test/flutter_test.dart';
import 'package:sarapp/models/app_settings.dart';
import 'package:sarapp/models/entry.dart';
import 'package:sarapp/services/analytics_service.dart';

void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────────

  String dateStr(int daysFrom2024Jan1) {
    final d = DateTime(2024, 1, 1).add(Duration(days: daysFrom2024Jan1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  AppSettings makeSettings(Set<String> enabled) => AppSettings(
        enabledModules: enabled,
        moduleOrder: enabled.toList(),
      );

  // ── Tests ─────────────────────────────────────────────────────────────────────

  group('AnalyticsService.computeAssociations', () {
    test('Spearman: detects strong negative correlation (happiness vs stress)', () {
      // 30 entries split evenly: high happiness / low stress, and the reverse.
      // Spearman ρ should be close to -1; effect size > 0.80, p << 0.05.
      final entries = [
        for (var i = 0; i < 15; i++)
          Entry(
            date: dateStr(i),
            happinessScore: 8,
            stressScore: 2,
            createdAt: '2024-01-01T00:00:00.000',
          ),
        for (var i = 15; i < 30; i++)
          Entry(
            date: dateStr(i),
            happinessScore: 2,
            stressScore: 8,
            createdAt: '2024-01-01T00:00:00.000',
          ),
      ];

      final results = AnalyticsService.computeAssociations(
        entries: entries,
        focus: const AnalyticsFocus(moduleKey: 'happiness'),
        settings: makeSettings({'happiness', 'stress'}),
      );

      expect(results, isNotEmpty);
      final r = results.first;
      expect(r.predictorKey, 'stress');
      expect(r.testName, 'Spearman ρ');
      expect(r.effectSize, greaterThan(0.80));
      expect(r.pValue, lessThan(0.05));
      expect(r.n, 30);
      // High-happiness group should show lower average stress
      expect(r.focusGroupValue, lessThan(r.comparisonGroupValue));
    });

    test('n < 15 guard: returns empty list', () {
      final entries = [
        for (var i = 0; i < 10; i++)
          Entry(
            date: dateStr(i),
            happinessScore: i.isEven ? 8 : 2,
            stressScore: i.isEven ? 2 : 8,
            createdAt: '2024-01-01T00:00:00.000',
          ),
      ];

      final results = AnalyticsService.computeAssociations(
        entries: entries,
        focus: const AnalyticsFocus(moduleKey: 'happiness'),
        settings: makeSettings({'happiness', 'stress'}),
      );

      expect(results, isEmpty);
    });

    test('Mann-Whitney: detects stress higher on sick days (event × scale)', () {
      // 15 sick entries (stress=8) + 15 healthy entries (stress=2).
      // rank-biserial r should be ≈1.0, p << 0.05.
      final entries = [
        for (var i = 0; i < 15; i++)
          Entry(
            date: dateStr(i),
            stressScore: 8,
            healthStatus: 'Sick',
            createdAt: '2024-01-01T00:00:00.000',
          ),
        for (var i = 15; i < 30; i++)
          Entry(
            date: dateStr(i),
            stressScore: 2,
            healthStatus: 'Healthy',
            createdAt: '2024-01-01T00:00:00.000',
          ),
      ];

      final results = AnalyticsService.computeAssociations(
        entries: entries,
        focus: const AnalyticsFocus(moduleKey: 'health', tag: 'Sick'),
        settings: makeSettings({'health', 'stress'}),
      );

      expect(results, isNotEmpty);
      final r = results.first;
      expect(r.predictorKey, 'stress');
      expect(r.testName, 'Mann-Whitney U');
      expect(r.effectSize, greaterThan(0.80));
      expect(r.pValue, lessThan(0.05));
      // Stress mean on sick days should be higher than on healthy days
      expect(r.focusGroupValue, greaterThan(r.comparisonGroupValue));
    });

    test('results sorted by effectSize descending', () {
      // Strong correlation for stress, weak for sleep.
      final entries = [
        for (var i = 0; i < 15; i++)
          Entry(
            date: dateStr(i),
            happinessScore: 8,
            stressScore: 2,
            sleepScore: i.isEven ? 7 : 4, // weak, noisy
            createdAt: '2024-01-01T00:00:00.000',
          ),
        for (var i = 15; i < 30; i++)
          Entry(
            date: dateStr(i),
            happinessScore: 2,
            stressScore: 8,
            sleepScore: i.isEven ? 4 : 7, // weak, noisy
            createdAt: '2024-01-01T00:00:00.000',
          ),
      ];

      final results = AnalyticsService.computeAssociations(
        entries: entries,
        focus: const AnalyticsFocus(moduleKey: 'happiness'),
        settings: makeSettings({'happiness', 'stress', 'sleep'}),
      );

      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].effectSize,
            greaterThanOrEqualTo(results[i + 1].effectSize));
      }
    });

    test('previousDay lag: detects predictor from the day before', () {
      // Even days: stress=8. Odd days: happiness=2 (following a high-stress day).
      // This creates a lag-1 signal: high stress on day D → low happiness on day D+1.
      final entries = [
        for (var i = 0; i < 30; i++)
          Entry(
            date: dateStr(i),
            happinessScore: i.isEven ? 8 : 2,
            stressScore: i.isEven ? 2 : 8,
            createdAt: '2024-01-01T00:00:00.000',
          ),
      ];

      final results = AnalyticsService.computeAssociations(
        entries: entries,
        focus: const AnalyticsFocus(moduleKey: 'happiness'),
        settings: makeSettings({'happiness', 'stress'}),
      );

      // At minimum the same-day association should surface; lag results are a bonus
      expect(results, isNotEmpty);
      expect(
        results.any((r) => r.lag == AssociationLag.previousDay),
        isTrue,
      );
    });
  });
}
