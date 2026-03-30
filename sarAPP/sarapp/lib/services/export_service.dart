import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/entry.dart';

class ExportService {
  static Future<void> exportToCsv(List<Entry> entries) async {
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
        'foods',
        'activities',
        'notes',
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
          e.foods.join(';'),
          e.activities.join(';'),
          e.notes,
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sarapp_export.csv');
    await file.writeAsString(csv);

    // Opens the OS share sheet (email, Drive, Files, etc.)
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'sarAPP Data Export',
    );
  }
}
