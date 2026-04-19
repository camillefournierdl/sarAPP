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
  final List<String> customEmotions;
  final List<String> customSymptoms;
  final List<String> customSports;
  final List<String> customLeisure;
  final List<String> customFoods;
  final List<String> customSickTags;
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
    this.customEmotions = const [
      '😊 Happy', '😢 Sad', '😤 Angry', '😰 Anxious', '😴 Tired', '⚡ Energized',
    ],
    this.customSymptoms = const [
      'cramps', 'bloating', 'headache', 'fatigue', 'mood swings', 'breast tenderness', 'back pain', 'acne',
    ],
    this.customSports = const [
      '🏋️ Weight lifting', '🏃 Intense cardio', '🚴 Endurance', '💃 Dance', '🧗 Climbing',
    ],
    this.customLeisure = const [
      '📖 Reading', '🌱 Gardening', '🎲 Board games', '🎮 Gaming',
    ],
    this.customFoods = const [
      '🌾 Gluten', '🥛 Lactose', '🍬 Sugars', '🍗 Chicken', '🐟 Fish',
    ],
    this.customSickTags = const [
      '🤧 Cold', '🤒 Flu', '🤢 Nausea', '🤕 Headache', '🔥 Fever', '🫄 Digestive issues', '😮‍💨 Fatigue',
    ],
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
    List<String>? customEmotions,
    List<String>? customSymptoms,
    List<String>? customSports,
    List<String>? customLeisure,
    List<String>? customFoods,
    List<String>? customSickTags,
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
        customEmotions: customEmotions ?? this.customEmotions,
        customSymptoms: customSymptoms ?? this.customSymptoms,
        customSports: customSports ?? this.customSports,
        customLeisure: customLeisure ?? this.customLeisure,
        customFoods: customFoods ?? this.customFoods,
        customSickTags: customSickTags ?? this.customSickTags,
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
