import 'app_module.dart';
import 'custom_module.dart';

class AppSettings {
  final bool menstruationTracking;
  final int notificationHour;
  final int notificationMinute;
  final bool notificationsEnabled;
  final bool onboardingComplete;
  final String? lastPeriodStart;
  final Set<String> enabledModules;
  /// null = follow device locale, 'monday', or 'sunday'
  final String? calendarStartDay;
  final bool showHighFertility;
  final bool showLastSex;
  /// Options for each module, keyed by module key (built-ins) or id (custom).
  final Map<String, List<String>> moduleOptions;
  /// User overrides for scale slider low labels, keyed by module key/id.
  final Map<String, String> moduleLabelLow;
  /// User overrides for scale slider high labels, keyed by module key/id.
  final Map<String, String> moduleLabelHigh;
  /// Follow-up options for conditional modules (built-ins keyed by module key).
  final Map<String, List<String>> moduleConditionalOptions;
  /// Trigger option value for conditional modules (built-ins keyed by module key).
  final Map<String, String> moduleConditionalTrigger;
  /// Follow-up question label for conditional modules (built-ins keyed by module key).
  final Map<String, String> moduleConditionalQuestion;
  final List<CustomModule> customModules;
  final Map<String, String> customModuleQuestions;
  final List<String> moduleOrder;

  const AppSettings({
    this.menstruationTracking = true,
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = false,
    this.onboardingComplete = false,
    this.lastPeriodStart,
    this.enabledModules = const {
      'happiness', 'emotions', 'sleep', 'weather', 'health', 'work', 'sports', 'leisure', 'food', 'notes'
    },
    this.calendarStartDay,
    this.showHighFertility = false,
    this.showLastSex = false,
    this.moduleOptions = const {
      'emotions': ['😊 Happy', '😢 Sad', '😤 Angry', '😰 Anxious', '😴 Tired', '⚡ Energized'],
      'symptoms': ['cramps', 'bloating', 'headache', 'fatigue', 'mood swings', 'breast tenderness', 'back pain', 'acne'],
      'sports':   ['🏋️ Weight lifting', '🏃 Intense cardio', '🚴 Endurance', '💃 Dance', '🧗 Climbing'],
      'leisure':  ['📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming', '🎵 Music (practice)', '🎶 Music (group)'],
      'food':     ['🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish'],
    },
    this.moduleLabelLow = const {},
    this.moduleLabelHigh = const {},
    this.moduleConditionalOptions = const {
      'health': ['🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '🔥 Fever', '🫄 Digestive issues', '😮‍💨 Fatigue'],
    },
    this.moduleConditionalTrigger = const {},
    this.moduleConditionalQuestion = const {},
    this.customModules = const [],
    this.customModuleQuestions = const {},
    this.moduleOrder = const [
      'happiness', 'emotions', 'sleep', 'stress', 'weather',
      'health', 'work', 'sports', 'leisure', 'food', 'water',
      'symptoms', 'libido', 'sex', 'notes',
    ],
  });

  bool get isMenstruationTracking => menstruationTracking;

  bool isModuleEnabled(String key) => enabledModules.contains(key);

  /// Returns user-customized options for a module, falling back to AppModule defaults.
  List<String> optionsFor(String key) =>
      moduleOptions[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.defaultOptions ??
      const [];

  /// Returns the effective low label for a scale module.
  String labelLowFor(String key) =>
      moduleLabelLow[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.labelLow ??
      '';

  /// Returns the effective high label for a scale module.
  String labelHighFor(String key) =>
      moduleLabelHigh[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.labelHigh ??
      '';

  /// Returns user-customized follow-up options for a conditional module.
  List<String> conditionalOptionsFor(String key) =>
      moduleConditionalOptions[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.conditionalDefaultOptions ??
      const [];

  /// Returns the effective conditional trigger for a conditional module.
  String conditionalTriggerFor(String key) =>
      moduleConditionalTrigger[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.conditionalTrigger ??
      '';

  /// Returns the effective conditional follow-up question for a conditional module.
  String conditionalQuestionFor(String key) =>
      moduleConditionalQuestion[key] ??
      AppModule.all.where((m) => m.key == key).firstOrNull?.conditionalQuestion ??
      '';

  AppSettings copyWith({
    bool? menstruationTracking,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? onboardingComplete,
    String? lastPeriodStart,
    Set<String>? enabledModules,
    Object? calendarStartDay = _sentinel,
    bool? showHighFertility,
    bool? showLastSex,
    Map<String, List<String>>? moduleOptions,
    Map<String, String>? moduleLabelLow,
    Map<String, String>? moduleLabelHigh,
    Map<String, List<String>>? moduleConditionalOptions,
    Map<String, String>? moduleConditionalTrigger,
    Map<String, String>? moduleConditionalQuestion,
    List<CustomModule>? customModules,
    Map<String, String>? customModuleQuestions,
    List<String>? moduleOrder,
  }) =>
      AppSettings(
        menstruationTracking: menstruationTracking ?? this.menstruationTracking,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        enabledModules: enabledModules ?? this.enabledModules,
        calendarStartDay: calendarStartDay == _sentinel
            ? this.calendarStartDay
            : calendarStartDay as String?,
        showHighFertility: showHighFertility ?? this.showHighFertility,
        showLastSex: showLastSex ?? this.showLastSex,
        moduleOptions: moduleOptions ?? this.moduleOptions,
        moduleLabelLow: moduleLabelLow ?? this.moduleLabelLow,
        moduleLabelHigh: moduleLabelHigh ?? this.moduleLabelHigh,
        moduleConditionalOptions: moduleConditionalOptions ?? this.moduleConditionalOptions,
        moduleConditionalTrigger: moduleConditionalTrigger ?? this.moduleConditionalTrigger,
        moduleConditionalQuestion: moduleConditionalQuestion ?? this.moduleConditionalQuestion,
        customModules: customModules ?? this.customModules,
        customModuleQuestions: customModuleQuestions ?? this.customModuleQuestions,
        moduleOrder: moduleOrder ?? this.moduleOrder,
      );

  String questionFor(String moduleKey, String defaultQuestion) =>
      customModuleQuestions[moduleKey] ?? defaultQuestion;

  /// Returns a copy with [key] toggled on or off.
  AppSettings withModuleToggled(String key) {
    final updated = Set<String>.from(enabledModules);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    return copyWith(enabledModules: updated);
  }
}

// Sentinel so copyWith can distinguish "not provided" from explicit null.
const Object _sentinel = Object();
