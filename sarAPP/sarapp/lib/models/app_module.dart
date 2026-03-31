/// Describes a toggleable questionnaire section.
class AppModule {
  final String key;
  final String label;
  final String description;
  final String emoji;
  /// If true, the module is only offered to female-mode users.
  final bool femaleOnly;

  const AppModule({
    required this.key,
    required this.label,
    required this.description,
    required this.emoji,
    this.femaleOnly = false,
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
    femaleOnly: true,
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
    'activity',
    'food',
    'notes',
  };
}
