import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/cycle_phase_selector.dart';
import '../widgets/emotion_tag_selector.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>().entries;
    final isFemale =
        context.watch<SettingsProvider>().settings.isMenstruationTracking;

    if (entries.isEmpty) {
      return const Center(child: Text('Log some entries to see charts.'));
    }

    // ── Emotion frequency (last 30 days) ──────────────────────────────────
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = entries
        .where((e) => DateTime.parse(e.date).isAfter(cutoff))
        .toList();

    final emotionCounts = <String, int>{};
    for (final e in recent) {
      for (final em in e.emotions) {
        emotionCounts[em] = (emotionCounts[em] ?? 0) + 1;
      }
    }

    final emotionBars = emotionCounts.entries.map((entry) {
      final idx = emotions.indexWhere((e) => e.value == entry.key);
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: emotionColor(entry.key),
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    // ── Cycle phase distribution ───────────────────────────────────────────
    Map<String, int> phaseCounts = {};
    if (isFemale) {
      for (final e in recent) {
        if (e.cyclePhase != null) {
          phaseCounts[e.cyclePhase!] =
              (phaseCounts[e.cyclePhase!] ?? 0) + 1;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Emotion bar chart ──────────────────────────────────────────────
        Text('Emotions — last 30 days',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (emotionBars.isEmpty)
          const Text('No emotion data yet.')
        else
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: emotionBars,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= emotions.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            emotions[idx].label.split(' ').last,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true, reservedSize: 24),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),

        // ── Cycle phase chart (female only) ───────────────────────────────
        if (isFemale) ...[
          const SizedBox(height: 32),
          Text('Cycle phases — last 30 days',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (phaseCounts.isEmpty)
            const Text('No cycle phase data yet.')
          else
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: phaseCounts.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${cyclePhaseLabel(entry.key)}\n${entry.value}d',
                      color: cyclePhaseColor(entry.key),
                      radius: 80,
                      titleStyle: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
