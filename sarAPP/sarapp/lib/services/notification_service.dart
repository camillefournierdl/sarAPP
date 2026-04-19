import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../providers/entries_provider.dart';
import '../screens/log_entry_screen.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Used by [SarApp] as the [MaterialApp.navigatorKey] so we can push routes
  /// from outside the widget tree when a notification is tapped.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const _channelId = 'sarapp_daily';
  static const _channelName = 'Daily reminder';
  static const _notifId = 0;

  static int _scheduledHour = 20;
  static int _scheduledMinute = 0;

  /// Set during cold-start (app launched by tapping a notification) so the
  /// first screen can pick it up after the widget tree is ready.
  static String? pendingLogDate;

  static Future<void> init({
    int notificationHour = 20,
    int notificationMinute = 0,
  }) async {
    _scheduledHour = notificationHour;
    _scheduledMinute = notificationMinute;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fall back to UTC offset so scheduling still fires at roughly the right time
      final hours = DateTime.now().timeZoneOffset.inHours;
      final sign = hours <= 0 ? '+' : '-'; // Etc/GMT sign is inverted
      try {
        tz.setLocalLocation(tz.getLocation('Etc/GMT$sign${hours.abs()}'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Cold start: app was opened by tapping the notification
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      pendingLogDate = intendedLogDate();
    }
  }

  static void _onTap(NotificationResponse _) {
    final date = intendedLogDate();
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Warm start: app already running, navigate immediately
      final existing = context.read<EntriesProvider>().getByDate(date);
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => existing != null
            ? LogEntryScreen(existing: existing)
            : LogEntryScreen(date: date),
      ));
    } else {
      // Widget tree not ready yet; HomeScreen will consume this on first frame
      pendingLogDate = date;
    }
  }

  /// The date (yyyy-MM-dd) this daily notification was intended for.
  /// If the current time is before today's scheduled fire time the notification
  /// came from yesterday (user opened it after midnight).
  static String intendedLogDate() {
    final now = DateTime.now();
    final fireToday = DateTime(
        now.year, now.month, now.day, _scheduledHour, _scheduledMinute);
    if (now.isBefore(fireToday)) {
      return DateFormat('yyyy-MM-dd')
          .format(now.subtract(const Duration(days: 1)));
    }
    return DateFormat('yyyy-MM-dd').format(now);
  }

  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    _scheduledHour = hour;
    _scheduledMinute = minute;
    await _plugin.cancel(_notifId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.zonedSchedule(
      _notifId,
      'Time to log your day',
      'How are you feeling today?',
      _nextInstanceOf(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
