class AppSettings {
  final String userMode; // 'female' or 'male'
  final int notificationHour;
  final int notificationMinute;
  final bool notificationsEnabled;
  final bool onboardingComplete;
  final String? lastPeriodStart; // YYYY-MM-DD of most recent period start
  final bool showSymptoms; // whether the symptoms question appears in the log form

  const AppSettings({
    this.userMode = 'female',
    this.notificationHour = 20,
    this.notificationMinute = 0,
    this.notificationsEnabled = false,
    this.onboardingComplete = false,
    this.lastPeriodStart,
    this.showSymptoms = false,
  });

  AppSettings copyWith({
    String? userMode,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? onboardingComplete,
    String? lastPeriodStart,
    bool? showSymptoms,
  }) =>
      AppSettings(
        userMode: userMode ?? this.userMode,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        showSymptoms: showSymptoms ?? this.showSymptoms,
      );

  bool get isFemaleMode => userMode == 'female';
}
