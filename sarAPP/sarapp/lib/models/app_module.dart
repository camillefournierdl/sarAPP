/// Describes a toggleable questionnaire section.
class AppModule {
  final String key;
  final String label;
  final String description;
  final String emoji;
  /// If true, the module is only shown when menstruation tracking is enabled.
  final bool menstruationOnly;

  const AppModule({
    required this.key,
    required this.label,
    required this.description,
    required this.emoji,
    this.menstruationOnly = false,
  });

  // ── Registry — add new modules here ──────────────────────────────────────

  static const happiness = AppModule(
    key: 'happiness',
    label: 'Happiness',
    description: 'Daily happiness scale (0 – 10)',
    emoji: '😊',
  );
  static const emotions = AppModule(
    key: 'emotions',
    label: 'Emotions',
    description: 'Emotion tag selection',
    emoji: '🎭',
  );
  static const sleep = AppModule(
    key: 'sleep',
    label: 'Sleep',
    description: 'Sleep quality scale (0 – 10)',
    emoji: '🔋',
  );
  static const weather = AppModule(
    key: 'weather',
    label: 'Weather',
    description: 'Weather rating scale (0 – 10)',
    emoji: '🌤️',
  );
  static const work = AppModule(
    key: 'work',
    label: 'Work',
    description: 'Work day type (off / half / full)',
    emoji: '💼',
  );
  static const sports = AppModule(
    key: 'sports',
    label: 'Sports',
    description: 'Physical sport tracking',
    emoji: '🏃',
  );
  static const leisure = AppModule(
    key: 'leisure',
    label: 'Leisure activities',
    description: 'Non-sport activity tracking (reading, gaming…)',
    emoji: '🎲',
  );
  static const food = AppModule(
    key: 'food',
    label: 'Food',
    description: 'Food category selection',
    emoji: '🍽️',
  );
  static const symptoms = AppModule(
    key: 'symptoms',
    label: 'Symptoms',
    description: 'Physical symptom tracking',
    emoji: '🩺',
    menstruationOnly: true,
  );
  static const health = AppModule(
    key: 'health',
    label: 'Health',
    description: 'General health status (healthy / sick)',
    emoji: '🤒',
  );
  static const notes = AppModule(
    key: 'notes',
    label: 'Notes',
    description: 'Free-text notes',
    emoji: '📝',
  );
  static const libido = AppModule(
    key: 'libido',
    label: 'Libido',
    description: 'Libido level (0 – 10)',
    emoji: '🔥',
  );
  static const sex = AppModule(
    key: 'sex',
    label: 'Sex',
    description: 'Had sex today?',
    emoji: '❤️',
  );
  static const water = AppModule(
    key: 'water',
    label: 'Water intake',
    description: 'Glasses of water today (0 – 10)',
    emoji: '💧',
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
