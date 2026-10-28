import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'l10n/app_localizations.dart';
import 'providers/analytics_provider.dart';
import 'providers/entries_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Required before any async calls before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite_common_ffi required for Windows/Linux desktop
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Make the status bar transparent with dark icons (white background)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Load settings first so we can pass the correct notification time to init
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  // Initialise notifications — passing the scheduled time so the cold-start
  // date calculation uses the user's actual reminder time, not the default.
  await NotificationService.init(
    notificationHour: settingsProvider.settings.notificationHour,
    notificationMinute: settingsProvider.settings.notificationMinute,
  );
  // Re-schedule on launch so the reminder text follows the current language
  // (e.g. after the device language changed).
  final s = settingsProvider.settings;
  if (s.notificationsEnabled) {
    await NotificationService.scheduleDailyReminder(
        s.notificationHour, s.notificationMinute,
        languageCode: s.languageCode);
  }

  final entriesProvider = EntriesProvider();
  await entriesProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: entriesProvider),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: const SarApp(),
    ),
  );
}

class SarApp extends StatelessWidget {
  const SarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch re-builds this widget when settings change,
    // so switching modes or completing onboarding is reflected immediately.
    final settings = context.watch<SettingsProvider>().settings;

    return MaterialApp(
      title: 'sarapp',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // null = follow the device language
      locale: settings.languageCode == null
          ? null
          : Locale(settings.languageCode!),
      builder: (context, child) {
        // Lets plain DateFormat(...) calls pick up the active language.
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return child!;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF), // purple
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: settings.onboardingComplete
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
