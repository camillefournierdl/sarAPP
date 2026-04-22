import 'dart:math';
import '../models/app_module.dart';
import '../models/app_settings.dart';
import '../models/custom_module.dart';
import '../models/entry.dart';

class AnalyticsFocus {
  final String moduleKey;
  final String? tag; // null = scale focus; non-null = event focus
  const AnalyticsFocus({required this.moduleKey, this.tag});
}

enum AssociationLag { sameDay, previousDay }

class AssociationResult {
  final String predictorKey;
  final String? predictorTag; // null if predictor is scale
  final AssociationLag lag;
  final double effectSize; // always positive (|ρ| or rank-biserial r)
  final double pValue;
  final int n;
  final String testName;
  final bool isLimitedData; // n < 30
  final double focusGroupValue; // mean or rate for the "focus" group
  final double comparisonGroupValue; // mean or rate for the comparison group

  const AssociationResult({
    required this.predictorKey,
    this.predictorTag,
    required this.lag,
    required this.effectSize,
    required this.pValue,
    required this.n,
    required this.testName,
    required this.isLimitedData,
    required this.focusGroupValue,
    required this.comparisonGroupValue,
  });
}

class AnalyticsService {
  const AnalyticsService._();

  // ── Statistics ──────────────────────────────────────────────────────────────

  // Abramowitz & Stegun 26.2.17 rational approximation; error < 7.5e-8
  static double _normalCdf(double z) {
    const p = 0.2316419;
    const b = [0.319381530, -0.356563782, 1.781477937, -1.821255978, 1.330274429];
    final absZ = z.abs();
    final t = 1.0 / (1.0 + p * absZ);
    var poly = 0.0;
    for (var i = 4; i >= 0; i--) {
      poly = poly * t + b[i];
    }
    poly *= t;
    final pdf = exp(-0.5 * absZ * absZ) / sqrt(2 * pi);
    final cdf = 1.0 - pdf * poly;
    return z >= 0 ? cdf : 1.0 - cdf;
  }

  static List<double> _rank(List<double> vals) {
    final n = vals.length;
    final idx = List.generate(n, (i) => i)
      ..sort((a, b) => vals[a].compareTo(vals[b]));
    final ranks = List<double>.filled(n, 0);
    var i = 0;
    while (i < n) {
      var j = i;
      while (j < n - 1 && vals[idx[j + 1]] == vals[idx[j]]) j++;
      final r = (i + j) / 2.0 + 1;
      for (var k = i; k <= j; k++) ranks[idx[k]] = r;
      i = j + 1;
    }
    return ranks;
  }

  static ({double r, double p, int n}) _spearman(List<double> x, List<double> y) {
    final n = x.length;
    final rx = _rank(x), ry = _rank(y);
    final mx = rx.fold(0.0, (a, b) => a + b) / n;
    final my = ry.fold(0.0, (a, b) => a + b) / n;
    double num = 0, sx = 0, sy = 0;
    for (var i = 0; i < n; i++) {
      final dx = rx[i] - mx, dy = ry[i] - my;
      num += dx * dy;
      sx += dx * dx;
      sy += dy * dy;
    }
    final denom = sqrt(sx * sy);
    final r = denom == 0 ? 0.0 : num / denom;
    if (r.abs() >= 1.0) return (r: r, p: 0.0, n: n);
    final t = r * sqrt((n - 2) / (1 - r * r));
    return (r: r, p: 2 * (1 - _normalCdf(t.abs())), n: n);
  }

  // group1 = "event" group; r is rank-biserial correlation (always returned positive)
  static ({double r, double p, int n}) _mannWhitney(
    List<double> group1,
    List<double> group2,
  ) {
    final n1 = group1.length, n2 = group2.length;
    if (n1 == 0 || n2 == 0) return (r: 0.0, p: 1.0, n: n1 + n2);
    var u = 0.0;
    for (final a in group1) {
      for (final b in group2) {
        if (a > b) {
          u += 1;
        } else if (a == b) {
          u += 0.5;
        }
      }
    }
    final sigma = sqrt(n1 * n2 * (n1 + n2 + 1) / 12.0);
    if (sigma == 0) return (r: 0.0, p: 1.0, n: n1 + n2);
    final z = (u - n1 * n2 / 2.0) / sigma;
    final r = (1 - 2 * u / (n1 * n2)).abs();
    return (r: r, p: 2 * (1 - _normalCdf(z.abs())), n: n1 + n2);
  }

  // ── Extraction ──────────────────────────────────────────────────────────────

  static double? _scaleValue(Entry e, String key) => switch (key) {
        'happiness' => e.happinessScore?.toDouble(),
        'sleep' => e.sleepScore?.toDouble(),
        'stress' => e.stressScore?.toDouble(),
        'weather' => e.weatherScore?.toDouble(),
        'libido' => e.libidoScore?.toDouble(),
        'water' => e.waterGlasses?.toDouble(),
        _ => (e.customData[key] as int?)?.toDouble(),
      };

  // Returns null when the module was not answered; true/false otherwise.
  static bool? _eventPresence(
    Entry e,
    String moduleKey,
    String tag,
    AppSettings settings,
  ) {
    // For list-based modules: determine if the user actually answered this module.
    // New entries: rely on answeredModules. Old entries (empty set): non-empty list = answered.
    bool listAnswered(List<String> list) {
      if (e.answeredModules.isNotEmpty) return e.answeredModules.contains(moduleKey);
      return list.isNotEmpty;
    }

    switch (moduleKey) {
      case 'emotions':
        if (!listAnswered(e.emotions)) return null;
        return e.emotions.contains(tag);
      case 'sports':
        if (!listAnswered(e.sports)) return null;
        return e.sports.contains(tag);
      case 'leisure':
        if (!listAnswered(e.leisure)) return null;
        return e.leisure.contains(tag);
      case 'food':
        if (!listAnswered(e.foods)) return null;
        return e.foods.contains(tag);
      case 'symptoms':
        if (!listAnswered(e.symptoms)) return null;
        return e.symptoms.contains(tag);
      case 'work':
        if (e.workDay == null) return null;
        if (e.workDay == tag) return true;
        // Graceful fallback for legacy entries that stored 'off'/'half'/'full'
        const legacy = {'🌿 Day off': 'off', '🌗 Half day': 'half', '💼 Full day': 'full'};
        return e.workDay!.toLowerCase() == (legacy[tag] ?? '');
      case 'sex':
        if (e.hadSex == null) return null;
        return e.hadSex!.toLowerCase() == tag.toLowerCase();
      case 'health':
        if (e.healthStatus == null) return null;
        final trigger = settings.conditionalTriggerFor('health');
        if (tag.toLowerCase() == trigger.toLowerCase()) {
          return e.healthStatus!.toLowerCase() == trigger.toLowerCase();
        }
        // Follow-up sick tag: valid observation when healthStatus is set
        return e.sickTags.contains(tag);
      default:
        // Custom module
        final m = settings.customModules.where((m) => m.id == moduleKey).firstOrNull;
        if (m == null) return null;
        switch (m.responseType) {
          case ResponseType.multiSelect:
            final list = List<String>.from(e.customData[moduleKey] as List? ?? []);
            if (!listAnswered(list)) return null;
            return list.contains(tag);
          case ResponseType.singleSelect:
            final val = e.customData[moduleKey] as String?;
            if (val == null) return null;
            return val == tag;
          case ResponseType.conditional:
            final data = (e.customData[moduleKey] as Map?)?.cast<String, dynamic>() ?? {};
            final primary = data['value'] as String?;
            if (primary == null) return null;
            if (m.conditionalTrigger != null && tag == m.conditionalTrigger) {
              return primary == m.conditionalTrigger;
            }
            final followup = List<String>.from(data['followup'] as List? ?? []);
            return followup.contains(tag);
          default:
            return null;
        }
    }
  }

  static ResponseType? _responseTypeOf(String key, AppSettings settings) =>
      AppModule.forKey(key)?.responseType ??
      settings.customModules.where((m) => m.id == key).firstOrNull?.responseType;

  // Returns (key, tag?) pairs: tag=null means scale predictor, string means event predictor.
  static List<(String, String?)> _enumeratePredictors(
    String key,
    AppSettings settings,
  ) {
    final type = _responseTypeOf(key, settings);
    if (type == null || type == ResponseType.text) return [];
    switch (type) {
      case ResponseType.scale:
        return [(key, null)];
      case ResponseType.multiSelect:
      case ResponseType.singleSelect:
        final opts = AppModule.forKey(key) != null
            ? settings.optionsFor(key)
            : (settings.customModules.where((m) => m.id == key).firstOrNull?.options ?? []);
        return opts.map((o) => (key, o)).toList();
      case ResponseType.conditional:
        if (AppModule.forKey(key) != null) {
          final trigger = settings.conditionalTriggerFor(key);
          final followups = settings.conditionalOptionsFor(key);
          return [(key, trigger), ...followups.map((o) => (key, o))];
        } else {
          final m = settings.customModules.where((m) => m.id == key).firstOrNull;
          if (m == null) return [];
          return [
            if (m.conditionalTrigger != null) (key, m.conditionalTrigger!),
            ...m.conditionalOptions.map((o) => (key, o)),
          ];
        }
      case ResponseType.text:
        return [];
    }
  }

  static String _prevDateStr(String dateStr) {
    final dt = DateTime.parse(dateStr).subtract(const Duration(days: 1));
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  static double _mean(Iterable<double> vals) =>
      vals.isEmpty ? 0 : vals.fold(0.0, (a, b) => a + b) / vals.length;

  // ── Main computation ────────────────────────────────────────────────────────

  static List<AssociationResult> computeAssociations({
    required List<Entry> entries,
    required AnalyticsFocus focus,
    required AppSettings settings,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final filtered = entries.where((e) {
      final d = DateTime.parse(e.date);
      if (windowStart != null && d.isBefore(windowStart)) return false;
      if (windowEnd != null && d.isAfter(windowEnd)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final byDate = {for (final e in filtered) e.date: e};
    if (_responseTypeOf(focus.moduleKey, settings) == null) return [];
    final isEventFocus = focus.tag != null;

    final predictorKeys = settings.enabledModules
        .where((key) =>
            key != focus.moduleKey &&
            _responseTypeOf(key, settings) != null &&
            _responseTypeOf(key, settings) != ResponseType.text)
        .toSet();

    final results = <AssociationResult>[];

    for (final lag in AssociationLag.values) {
      for (final predictorKey in predictorKeys) {
        for (final (predKey, predTag) in _enumeratePredictors(predictorKey, settings)) {
          final isScalePredictor = predTag == null;

          // Event × Event → skipped in v1
          if (isEventFocus && !isScalePredictor) continue;

          if (!isEventFocus && isScalePredictor) {
            // ── Scale × Scale → Spearman ρ ──────────────────────────────────
            final xVals = <double>[], yVals = <double>[];
            for (final entry in filtered) {
              final src = lag == AssociationLag.sameDay
                  ? entry
                  : byDate[_prevDateStr(entry.date)];
              if (src == null) continue;
              final fx = _scaleValue(entry, focus.moduleKey);
              final py = _scaleValue(src, predKey);
              if (fx == null || py == null) continue;
              xVals.add(fx);
              yVals.add(py);
            }
            if (xVals.length < 15) continue;
            final res = _spearman(xVals, yVals);
            if (res.r.abs() < 0.20) continue;
            final pCutoff = res.n < 30 ? 0.10 : 0.05;
            if (res.p >= pCutoff) continue;

            // focusGroupValue = mean predictor in top-third focus days
            // comparisonGroupValue = mean predictor in bottom-third focus days
            final pairs = List.generate(xVals.length, (i) => (xVals[i], yVals[i]));
            pairs.sort((a, b) => a.$1.compareTo(b.$1));
            final third = (pairs.length ~/ 3).clamp(1, pairs.length);
            final fgv = _mean(pairs.sublist(pairs.length - third).map((p) => p.$2));
            final cgv = _mean(pairs.sublist(0, third).map((p) => p.$2));

            results.add(AssociationResult(
              predictorKey: predKey,
              predictorTag: null,
              lag: lag,
              effectSize: res.r.abs(),
              pValue: res.p,
              n: res.n,
              testName: 'Spearman ρ',
              isLimitedData: res.n < 30,
              focusGroupValue: fgv,
              comparisonGroupValue: cgv,
            ));
          } else if (!isEventFocus && !isScalePredictor) {
            // ── Scale × Event → Mann-Whitney U ──────────────────────────────
            // Groups: focus scale values split by whether predictor event occurred
            final eventFocus = <double>[], noEventFocus = <double>[];
            for (final entry in filtered) {
              final src = lag == AssociationLag.sameDay
                  ? entry
                  : byDate[_prevDateStr(entry.date)];
              if (src == null) continue;
              final fx = _scaleValue(entry, focus.moduleKey);
              if (fx == null) continue;
              final ev = _eventPresence(src, predKey, predTag!, settings);
              if (ev == null) continue;
              (ev ? eventFocus : noEventFocus).add(fx);
            }
            final n = eventFocus.length + noEventFocus.length;
            if (n < 15) continue;
            if (eventFocus.isEmpty || noEventFocus.isEmpty) continue;
            final res = _mannWhitney(eventFocus, noEventFocus);
            if (res.r < 0.20) continue;
            final pCutoff = res.n < 30 ? 0.10 : 0.05;
            if (res.p >= pCutoff) continue;

            // Rate of "high focus" days in each group (for display as %)
            final all = [...eventFocus, ...noEventFocus]..sort();
            final topThreshold = all[(all.length * 2) ~/ 3];
            final fgv = eventFocus.where((v) => v >= topThreshold).length / eventFocus.length;
            final cgv = noEventFocus.where((v) => v >= topThreshold).length / noEventFocus.length;

            results.add(AssociationResult(
              predictorKey: predKey,
              predictorTag: predTag,
              lag: lag,
              effectSize: res.r,
              pValue: res.p,
              n: res.n,
              testName: 'Mann-Whitney U',
              isLimitedData: res.n < 30,
              focusGroupValue: fgv,
              comparisonGroupValue: cgv,
            ));
          } else if (isEventFocus && isScalePredictor) {
            // ── Event × Scale → Mann-Whitney U ──────────────────────────────
            // Groups: predictor scale values split by whether focus event occurred
            final eventPred = <double>[], noEventPred = <double>[];
            for (final entry in filtered) {
              final src = lag == AssociationLag.sameDay
                  ? entry
                  : byDate[_prevDateStr(entry.date)];
              if (src == null) continue;
              final pv = _scaleValue(src, predKey);
              if (pv == null) continue;
              final ev = _eventPresence(entry, focus.moduleKey, focus.tag!, settings);
              if (ev == null) continue;
              (ev ? eventPred : noEventPred).add(pv);
            }
            final n = eventPred.length + noEventPred.length;
            if (n < 15) continue;
            if (eventPred.isEmpty || noEventPred.isEmpty) continue;
            final res = _mannWhitney(eventPred, noEventPred);
            if (res.r < 0.20) continue;
            final pCutoff = res.n < 30 ? 0.10 : 0.05;
            if (res.p >= pCutoff) continue;

            results.add(AssociationResult(
              predictorKey: predKey,
              predictorTag: null,
              lag: lag,
              effectSize: res.r,
              pValue: res.p,
              n: res.n,
              testName: 'Mann-Whitney U',
              isLimitedData: res.n < 30,
              focusGroupValue: _mean(eventPred),
              comparisonGroupValue: _mean(noEventPred),
            ));
          }
        }
      }
    }

    results.sort((a, b) => b.effectSize.compareTo(a.effectSize));
    return results;
  }
}
