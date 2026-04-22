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
  final int? sleepScore;     // 0–10, null = not answered
  final int? stressScore;    // 0–10, null = not answered
  final int? weatherScore;   // 0–10, null = not answered
  final String? workDay;     // 'off' | 'half' | 'full' | null = not answered
  final List<String> foods; // e.g. ['gluten', 'lactose']
  final List<String> sports; // e.g. ['🏋️ Weight lifting', '🏃 Intense cardio']
  final List<String> leisure; // e.g. ['📖 Reading', '🎮 Gaming']
  final String? healthStatus;   // 'healthy' | 'sick' | null = not answered
  final List<String> sickTags;  // e.g. ['cold', 'nausea']
  final String notes;
  final int? libidoScore;    // 0–10, null = not answered
  final String? hadSex;      // 'yes' | 'no' | null = not answered
  final int? waterGlasses;   // 0–10, null = not answered
  final Map<String, dynamic> customData;
  final Set<String> answeredModules; // keys shown to user at log time; empty on old entries
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
    this.sleepScore,
    this.stressScore,
    this.weatherScore,
    this.workDay,
    this.foods = const [],
    this.sports = const [],
    this.leisure = const [],
    this.healthStatus,
    this.sickTags = const [],
    this.notes = '',
    this.libidoScore,
    this.hadSex,
    this.waterGlasses,
    this.customData = const {},
    this.answeredModules = const {},
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
    int? sleepScore,
    int? stressScore,
    int? weatherScore,
    String? workDay,
    List<String> foods = const [],
    List<String> sports = const [],
    List<String> leisure = const [],
    String? healthStatus,
    List<String> sickTags = const [],
    String notes = '',
    int? libidoScore,
    String? hadSex,
    int? waterGlasses,
    Map<String, dynamic> customData = const {},
    Set<String> answeredModules = const {},
  }) =>
      Entry(
        date: date,
        emotions: emotions,
        cyclePhase: cyclePhase,
        periodStart: periodStart,
        periodEnd: periodEnd,
        symptoms: symptoms,
        happinessScore: happinessScore,
        sleepScore: sleepScore,
        stressScore: stressScore,
        weatherScore: weatherScore,
        workDay: workDay,
        foods: foods,
        sports: sports,
        leisure: leisure,
        healthStatus: healthStatus,
        sickTags: sickTags,
        notes: notes,
        libidoScore: libidoScore,
        hadSex: hadSex,
        waterGlasses: waterGlasses,
        customData: customData,
        answeredModules: answeredModules,
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
        'sleep_score': sleepScore,
        'stress_score': stressScore,
        'weather_score': weatherScore,
        'work_day': workDay,
        'foods': jsonEncode(foods),
        'sports': jsonEncode(sports),
        'leisure': jsonEncode(leisure),
        'health_status': healthStatus,
        'sick_tags': jsonEncode(sickTags),
        'notes': notes,
        'libido_score': libidoScore,
        'had_sex': hadSex,
        'water_glasses': waterGlasses,
        'custom_data': jsonEncode(customData),
        'answered_modules': jsonEncode(answeredModules.toList()),
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
        sleepScore: map['sleep_score'] as int?,
        stressScore: map['stress_score'] as int?,
        weatherScore: map['weather_score'] as int?,
        workDay: map['work_day'] as String?,
        foods: List<String>.from(
            jsonDecode(map['foods'] as String? ?? '[]')),
        sports: List<String>.from(
            jsonDecode(map['sports'] as String? ?? map['activities'] as String? ?? '[]')),
        leisure: List<String>.from(
            jsonDecode(map['leisure'] as String? ?? '[]')),
        healthStatus: map['health_status'] as String?,
        sickTags: List<String>.from(
            jsonDecode(map['sick_tags'] as String? ?? '[]')),
        notes: map['notes'] as String? ?? '',
        libidoScore: map['libido_score'] as int?,
        hadSex: map['had_sex'] as String?,
        waterGlasses: map['water_glasses'] as int?,
        customData: Map<String, dynamic>.from(
            jsonDecode(map['custom_data'] as String? ?? '{}') as Map),
        answeredModules: Set<String>.from(
            jsonDecode(map['answered_modules'] as String? ?? '[]') as List),
        createdAt: map['created_at'] as String,
      );

  /// True if the entry contains at least one piece of logged data.
  bool get hasData =>
      emotions.isNotEmpty ||
      happinessScore != null ||
      sleepScore != null ||
      stressScore != null ||
      weatherScore != null ||
      workDay != null ||
      sports.isNotEmpty ||
      leisure.isNotEmpty ||
      foods.isNotEmpty ||
      symptoms.isNotEmpty ||
      healthStatus != null ||
      notes.isNotEmpty ||
      libidoScore != null ||
      hadSex != null ||
      waterGlasses != null ||
      periodStart ||
      periodEnd ||
      customData.isNotEmpty;
}
