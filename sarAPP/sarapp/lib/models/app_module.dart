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
  static const activity = AppModule(
    key: 'activity',
    label: 'Physical activity',
    description: 'Activity type selection',
    emoji: '🏃',
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
  static const notes = AppModule(
    key: 'notes',
    label: 'Notes',
    description: 'Free-text notes',
    emoji: '📝',
  );

  /// All modules in questionnaire display order.
  static const List<AppModule> all = [
    happiness,
    emotions,
    sleep,
    weather,
    work,
    activity,
    food,
    symptoms,
    notes,
  ];

  /// Modules enabled by default (symptoms is opt-in).
  static const Set<String> defaultEnabled = {
    'happiness',
    'emotions',
    'sleep',
    'weather',
    'work',
    'activity',
    'food',
    'notes',
  };
}
