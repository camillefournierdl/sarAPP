import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_settings.dart';
import '../models/custom_module.dart';
import '../models/entry.dart';

class ExportService {
  static Future<void> exportToCsv(List<Entry> entries, AppSettings settings) async {
    final customModules = settings.customModules;

    final rows = <List<dynamic>>[
      // Header row
      [
        'date',
        'emotions',
        'cycle_phase',
        'period_start',
        'period_end',
        'symptoms',
        'happiness_score',
        'sleep_score',
        'stress_score',
        'weather_score',
        'work_day',
        'foods',
        'substances',
        'sports',
        'leisure',
        'notes',
        'health_status',
        'sick_tags',
        'libido_score',
        'had_sex',
        'water_glasses',
        ...customModules.map((m) => m.name),
      ],
      // Data rows
      ...entries.map(
        (e) => [
          e.date,
          e.emotions.join(';'),
          e.cyclePhase ?? '',
          e.periodStart ? 1 : 0,
          e.periodEnd ? 1 : 0,
          e.symptoms.join(';'),
          e.happinessScore ?? '',
          e.sleepScore ?? '',
          e.stressScore ?? '',
          e.weatherScore ?? '',
          e.workDay ?? '',
          e.foods.join(';'),
          e.substances.join(';'),
          e.sports.join(';'),
          e.leisure.join(';'),
          e.notes,
          e.healthStatus ?? '',
          e.sickTags.join(';'),
          e.libidoScore ?? '',
          e.hadSex ?? '',
          e.waterGlasses ?? '',
          ...customModules.map(
            (m) => _serializeCustomValue(e.customData[m.id], m.responseType),
          ),
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sarapp_export.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'sarapp data export',
    );
  }

  static String _serializeCustomValue(dynamic value, ResponseType type) {
    if (value == null) return '';
    switch (type) {
      case ResponseType.scale:
        return value.toString();
      case ResponseType.multiSelect:
        return (value as List).join(';');
      case ResponseType.singleSelect:
        return value as String;
      case ResponseType.text:
        return value as String;
      case ResponseType.conditional:
        final map = value as Map;
        final primary = map['value'] as String? ?? '';
        final followup = (map['followup'] as List?)?.join(';') ?? '';
        return followup.isEmpty ? primary : '$primary;$followup';
    }
  }
}
