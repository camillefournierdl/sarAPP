// Notifications are stubbed out for v1.
// flutter_local_notifications will be added back once the core app is stable.
class NotificationService {
  static Future<void> init() async {}
  static Future<bool> requestPermission() async => false;
  static Future<void> scheduleDailyReminder(int hour, int minute) async {}
  static Future<void> cancelAll() async {}
}
