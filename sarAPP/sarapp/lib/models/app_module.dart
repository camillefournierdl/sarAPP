import 'custom_module.dart';

/// Describes a toggleable questionnaire section.
class AppModule {
  final String key;
  final String label;
  final String description;
  final String emoji;
  final bool menstruationOnly;
  final ResponseType responseType;
  final List<String> defaultOptions;
  final String labelLow;
  final String labelHigh;
  /// For conditional modules: the primary option value that reveals the follow-up.
  final String conditionalTrigger;
  /// For conditional modules: the follow-up question label.
  final String conditionalQuestion;
  /// For conditional modules: the default follow-up options.
  final List<String> conditionalDefaultOptions;

  const AppModule({
    required this.key,
    required this.label,
    required this.description,
    required this.emoji,
    this.menstruationOnly = false,
    this.responseType = ResponseType.scale,
    this.defaultOptions = const [],
    this.labelLow = '',
    this.labelHigh = '',
    this.conditionalTrigger = '',
    this.conditionalQuestion = '',
    this.conditionalDefaultOptions = const [],
  });

  // ── Registry — add new modules here ──────────────────────────────────────

  static const happiness = AppModule(
    key: 'happiness',
    label: 'Happiness',
    description: 'Daily happiness scale (0 – 10)',
    emoji: '😊',
    responseType: ResponseType.scale,
  );
  static const emotions = AppModule(
    key: 'emotions',
    label: 'Emotions',
    description: 'How did you feel today?',
    emoji: '🎭',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '😊 Happy', '😢 Sad', '😤 Angry', '😰 Anxious', '😴 Tired', '⚡ Energized',
    ],
  );
  static const sleep = AppModule(
    key: 'sleep',
    label: 'Sleep',
    description: 'Sleep quality scale (0 – 10)',
    emoji: '🔋',
    responseType: ResponseType.scale,
    labelLow: '🪫',
    labelHigh: '🔋',
  );
  static const stress = AppModule(
    key: 'stress',
    label: 'Stress',
    description: 'Stress level (0 – 10)',
    emoji: '🧘',
    responseType: ResponseType.scale,
    labelLow: '😌',
    labelHigh: '😤',
  );
  static const weather = AppModule(
    key: 'weather',
    label: 'Weather',
    description: 'Weather rating scale (0 – 10)',
    emoji: '🌤️',
    responseType: ResponseType.scale,
    labelLow: '🌧️',
    labelHigh: '☀️',
  );
  static const work = AppModule(
    key: 'work',
    label: 'Work',
    description: 'Work day type',
    emoji: '💼',
    responseType: ResponseType.singleSelect,
    defaultOptions: ['🌿 Day off', '🌗 Half day', '💼 Full day'],
  );
  static const sports = AppModule(
    key: 'sports',
    label: 'Sports',
    description: 'Physical sport tracking',
    emoji: '🏃',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '🏋️ Weight lifting', '🏃 Intense cardio', '🚴 Endurance', '💃 Dance', '🧗 Climbing',
    ],
  );
  static const leisure = AppModule(
    key: 'leisure',
    label: 'Leisure activities',
    description: 'Other activity tracking',
    emoji: '♟️',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming',
      '🎵 Music (practice)', '🎶 Music (group)',
    ],
  );
  static const food = AppModule(
    key: 'food',
    label: 'Food',
    description: 'Food category selection',
    emoji: '🍽️',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🥩 Red meat',
      '🍖 Other meat', '🐟 Fish',
    ],
  );
  static const substances = AppModule(
    key: 'substances',
    label: 'Substances',
    description: 'Alcohol, caffeine, nicotine & more',
    emoji: '🍷',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '🍷 Alcohol', '☕ Caffeine', '🚬 Nicotine', '🌿 Cannabis', '💊 Medication',
    ],
  );
  static const symptoms = AppModule(
    key: 'symptoms',
    label: 'Symptoms',
    description: 'Chronic symptom tracking',
    emoji: '🩺',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      'cramps', 'bloating', 'headache', 'fatigue', 'mood swings',
      'breast tenderness', 'back pain', 'acne',
    ],
  );
  static const health = AppModule(
    key: 'health',
    label: 'Health',
    description: 'How did you feel physically today?',
    emoji: '🤒',
    responseType: ResponseType.conditional,
    defaultOptions: ['Healthy', 'Sick'],
    conditionalTrigger: 'Sick',
    conditionalQuestion: 'What was wrong? (optional)',
    conditionalDefaultOptions: [
      '🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '🔥 Fever',
      '🫄 Digestive issues', '😮‍💨 Fatigue',
    ],
  );
  static const notes = AppModule(
    key: 'notes',
    label: 'Notes',
    description: 'Free-text notes',
    emoji: '📝',
    responseType: ResponseType.text,
  );
  static const libido = AppModule(
    key: 'libido',
    label: 'Libido',
    description: 'Libido level (0 – 10)',
    emoji: '🔥',
    responseType: ResponseType.scale,
    labelLow: '💤',
    labelHigh: '🔥',
  );
  static const sex = AppModule(
    key: 'sex',
    label: 'Sex',
    description: 'Had sex today?',
    emoji: '❤️',
    responseType: ResponseType.singleSelect,
    defaultOptions: ['Yes', 'No'],
  );
  static const water = AppModule(
    key: 'water',
    label: 'Water intake',
    description: 'Glasses of water today (0 – 10)',
    emoji: '💧',
    responseType: ResponseType.scale,
    labelLow: '🏜️',
    labelHigh: '🐸',
  );

  /// Returns the built-in module with the given key, or null if not found.
  static AppModule? forKey(String key) =>
      all.where((m) => m.key == key).firstOrNull;

  /// All modules in questionnaire display order.
  static const List<AppModule> all = [
    happiness,
    emotions,
    sleep,
    stress,
    weather,
    health,
    work,
    sports,
    leisure,
    food,
    substances,
    symptoms,
    libido,
    sex,
    water,
    notes,
  ];

  /// Modules enabled by default (opt-in modules are excluded).
  static const Set<String> defaultEnabled = {
    'happiness',
    'emotions',
    'sleep',
    'stress',
    'weather',
    'health',
    'work',
    'sports',
    'leisure',
    'food',
    'notes',
  };
}
