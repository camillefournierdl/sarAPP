import 'dart:convert';

class Entry {
  final int? id;
  final String date; // YYYY-MM-DD
  final List<String> emotions;
  final String? cyclePhase; // menstruation | follicular | ovulation | luteal
  final bool periodStart;
  final bool periodEnd;
  final List<String> symptoms;
  final int? happinessScore; // 0–10, null = not answered
  final List<String> foods; // e.g. ['gluten', 'lactose']
  final List<String> activities; // e.g. ['weight_lifting', 'cardio']
  final String notes;
  final String createdAt;

  const Entry({
    this.id,
    required this.date,
    this.emotions = const [],
    this.cyclePhase,
    this.periodStart = false,
    this.periodEnd = false,
    this.symptoms = const [],
    this.happinessScore,
    this.foods = const [],
    this.activities = const [],
    this.notes = '',
    required this.createdAt,
  });

  factory Entry.create({
    required String date,
    List<String> emotions = const [],
    String? cyclePhase,
    bool periodStart = false,
    bool periodEnd = false,
    List<String> symptoms = const [],
    int? happinessScore,
    List<String> foods = const [],
    List<String> activities = const [],
    String notes = '',
  }) =>
      Entry(
        date: date,
        emotions: emotions,
        cyclePhase: cyclePhase,
        periodStart: periodStart,
        periodEnd: periodEnd,
        symptoms: symptoms,
        happinessScore: happinessScore,
        foods: foods,
        activities: activities,
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'emotions': jsonEncode(emotions),
        'cycle_phase': cyclePhase,
        'period_start': periodStart ? 1 : 0,
        'period_end': periodEnd ? 1 : 0,
        'symptoms': jsonEncode(symptoms),
        'happiness_score': happinessScore,
        'foods': jsonEncode(foods),
        'activities': jsonEncode(activities),
        'notes': notes,
        'created_at': createdAt,
      };

  factory Entry.fromMap(Map<String, dynamic> map) => Entry(
        id: map['id'] as int?,
        date: map['date'] as String,
        emotions: List<String>.from(
            jsonDecode(map['emotions'] as String? ?? '[]')),
        cyclePhase: map['cycle_phase'] as String?,
        periodStart: (map['period_start'] as int? ?? 0) == 1,
        periodEnd: (map['period_end'] as int? ?? 0) == 1,
        symptoms: List<String>.from(
            jsonDecode(map['symptoms'] as String? ?? '[]')),
        happinessScore: map['happiness_score'] as int?,
        foods: List<String>.from(
            jsonDecode(map['foods'] as String? ?? '[]')),
        activities: List<String>.from(
            jsonDecode(map['activities'] as String? ?? '[]')),
        notes: map['notes'] as String? ?? '',
        createdAt: map['created_at'] as String,
      );

  /// True if the entry contains at least one piece of logged data.
  bool get hasData =>
      emotions.isNotEmpty ||
      happinessScore != null ||
      activities.isNotEmpty ||
      foods.isNotEmpty ||
      symptoms.isNotEmpty ||
      notes.isNotEmpty ||
      periodStart ||
      periodEnd;
}
