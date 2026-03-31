import 'app_module.dart';

class AppSettings {
  final String userMode; // 'female' or 'male'
  final int notificationHour;
  final int notificationMinute;
  final bool notificationsEnabled;
  final bool onboardingComplete;
  final String? lastPeriodStart;
  final Set<String> enabledModules;

  const AppSettings({
    this.userMode = 'female',
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = false,
    this.onboardingComplete = false,
    this.lastPeriodStart,
    this.enabledModules = const {
      'happiness', 'emotions', 'sleep', 'activity', 'food', 'notes'
    },
  });

  bool get isFemaleMode => userMode == 'female';

  bool isModuleEnabled(String key) => enabledModules.contains(key);

  AppSettings copyWith({
    String? userMode,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? onboardingComplete,
    String? lastPeriodStart,
    Set<String>? enabledModules,
  }) =>
      AppSettings(
        userMode: userMode ?? this.userMode,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        enabledModules: enabledModules ?? this.enabledModules,
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
