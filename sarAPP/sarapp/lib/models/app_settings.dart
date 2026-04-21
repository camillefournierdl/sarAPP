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
  /// Module keys whose options the user has explicitly edited. Only these use
  /// the stored [moduleOptions] value; all others fall back to AppModule defaults
  /// so that default-option updates in new app versions are picked up automatically.
  final Set<String> userModifiedModuleOptions;
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
    this.moduleOptions = const {},
    this.userModifiedModuleOptions = const {},
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

  /// Returns options for a module. Uses stored value only if the user has
  /// explicitly edited this module's options; otherwise returns AppModule
  /// defaults so that new defaults are picked up automatically on app updates.
  List<String> optionsFor(String key) {
    if (userModifiedModuleOptions.contains(key)) {
      return moduleOptions[key] ?? AppModule.forKey(key)?.defaultOptions ?? const [];
    }
    return AppModule.forKey(key)?.defaultOptions ?? moduleOptions[key] ?? const [];
  }

  /// Returns the effective low label for a scale module.
  String labelLowFor(String key) =>
      moduleLabelLow[key] ?? AppModule.forKey(key)?.labelLow ?? '';

  /// Returns the effective high label for a scale module.
  String labelHighFor(String key) =>
      moduleLabelHigh[key] ?? AppModule.forKey(key)?.labelHigh ?? '';

  /// Returns user-customized follow-up options for a conditional module.
  List<String> conditionalOptionsFor(String key) =>
      moduleConditionalOptions[key] ??
      AppModule.forKey(key)?.conditionalDefaultOptions ??
      const [];

  /// Returns the effective conditional trigger for a conditional module.
  String conditionalTriggerFor(String key) =>
      moduleConditionalTrigger[key] ??
      AppModule.forKey(key)?.conditionalTrigger ??
      '';

  /// Returns the effective conditional follow-up question for a conditional module.
  String conditionalQuestionFor(String key) =>
      moduleConditionalQuestion[key] ??
      AppModule.forKey(key)?.conditionalQuestion ??
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
    Set<String>? userModifiedModuleOptions,
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
        userModifiedModuleOptions: userModifiedModuleOptions ?? this.userModifiedModuleOptions,
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
