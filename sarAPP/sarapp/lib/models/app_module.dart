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
    description: 'Emotion tag selection',
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
    description: 'Work day type (off / half / full)',
    emoji: '💼',
    responseType: ResponseType.singleSelect,
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
    description: 'Other activity tracking (reading, gardening…)',
    emoji: '🎲',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming',
    ],
  );
  static const food = AppModule(
    key: 'food',
    label: 'Food',
    description: 'Food category selection',
    emoji: '🍽️',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      '🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish',
    ],
  );
  static const symptoms = AppModule(
    key: 'symptoms',
    label: 'Symptoms',
    description: 'Physical symptom tracking',
    emoji: '🩺',
    menstruationOnly: true,
    responseType: ResponseType.multiSelect,
    defaultOptions: [
      'cramps', 'bloating', 'headache', 'fatigue', 'mood swings',
      'breast tenderness', 'back pain', 'acne',
    ],
  );
  static const health = AppModule(
    key: 'health',
    label: 'Health',
    description: 'General health status (healthy / sick)',
    emoji: '🤒',
    responseType: ResponseType.multiSelect,
    defaultOptions: [
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

  /// All modules in questionnaire display order.
  static const List<AppModule> all = [
    happiness,
    emotions,
    sleep,
    weather,
    health,
    work,
    sports,
    leisure,
    food,
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
    'weather',
    'health',
    'work',
    'sports',
    'leisure',
    'food',
    'notes',
  };
}
