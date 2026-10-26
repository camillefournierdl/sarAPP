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
    Map<String, List<String>> moduleOptions = const {},
  }) async {
    await update(_settings.copyWith(
      menstruationTracking: menstruationTracking,
      onboardingComplete: true,
      enabledModules: enabledModules,
      moduleOptions: {..._settings.moduleOptions, ...moduleOptions},
      userModifiedModuleOptions: {
        ..._settings.userModifiedModuleOptions,
        ...moduleOptions.keys,
      },
    ));
  }

  Future<void> setPeriodBaseline(String lastPeriodStart) async {
    await update(_settings.copyWith(lastPeriodStart: lastPeriodStart));
  }

  /// Clears the last period start date.
  Future<void> clearPeriodBaseline() async {
    await update(_settings.copyWith(lastPeriodStart: null));
  }

  /// Returns false if [enabled] was requested but notification permission
  /// was denied; reminders are then left off.
  Future<bool> setNotification({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (enabled) {
      if (!await NotificationService.requestPermission()) return false;
      await NotificationService.scheduleDailyReminder(hour, minute);
    } else {
      await NotificationService.cancelAll();
    }
    await update(_settings.copyWith(
      notificationsEnabled: enabled,
      notificationHour: hour,
      notificationMinute: minute,
    ));
    return true;
  }
}
