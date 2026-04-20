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
      'leisure':  ['📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming'],
      'food':     ['🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish'],
      'health':   ['🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '🔥 Fever', '🫄 Digestive issues', '😮‍💨 Fatigue'],
    },
    this.moduleLabelLow = const {},
    this.moduleLabelHigh = const {},
    this.customModules = const [],
    this.customModuleQuestions = const {},
    this.moduleOrder = const [
      'happiness', 'emotions', 'sleep', 'weather',
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
