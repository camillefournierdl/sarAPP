import 'app_module.dart';

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

  const AppSettings({
    this.menstruationTracking = true,
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = false,
    this.onboardingComplete = false,
    this.lastPeriodStart,
    this.enabledModules = const {
      'happiness', 'emotions', 'sleep', 'weather', 'work', 'activity', 'food', 'notes'
    },
    this.calendarStartDay,
    this.showHighFertility = false,
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
      );

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
