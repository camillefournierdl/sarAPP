import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await DatabaseService.loadSettings();
    notifyListeners();
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    await DatabaseService.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> setOnboardingComplete({
    required bool menstruationTracking,
    required Set<String> enabledModules,
  }) async {
    await update(_settings.copyWith(
      menstruationTracking: menstruationTracking,
      onboardingComplete: true,
      enabledModules: enabledModules,
    ));
  }

  Future<void> setPeriodBaseline(String lastPeriodStart) async {
    await update(_settings.copyWith(lastPeriodStart: lastPeriodStart));
  }

  /// Clears the last period start date.
  /// Uses explicit reconstruction because copyWith can't set a field to null.
  Future<void> clearPeriodBaseline() async {
    _settings = AppSettings(
      menstruationTracking: _settings.menstruationTracking,
      notificationHour: _settings.notificationHour,
      notificationMinute: _settings.notificationMinute,
      notificationsEnabled: _settings.notificationsEnabled,
      onboardingComplete: _settings.onboardingComplete,
      lastPeriodStart: null,
      enabledModules: _settings.enabledModules,
      calendarStartDay: _settings.calendarStartDay,
      showHighFertility: _settings.showHighFertility,
      showLastSex: _settings.showLastSex,
      moduleOptions: _settings.moduleOptions,
      moduleLabelLow: _settings.moduleLabelLow,
      moduleLabelHigh: _settings.moduleLabelHigh,
      customModules: _settings.customModules,
      customModuleQuestions: _settings.customModuleQuestions,
      moduleOrder: _settings.moduleOrder,
    );
    await DatabaseService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setNotification({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (enabled) {
      await NotificationService.scheduleDailyReminder(hour, minute);
    } else {
      await NotificationService.cancelAll();
    }
    await update(_settings.copyWith(
      notificationsEnabled: enabled,
      notificationHour: hour,
      notificationMinute: minute,
    ));
  }
}
