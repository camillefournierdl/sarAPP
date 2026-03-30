import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/entries_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Required before any async calls before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise notifications (sets up timezone + plugin)
  await NotificationService.init();

  // Load persisted data before the first frame
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  final entriesProvider = EntriesProvider();
  await entriesProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: entriesProvider),
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
      title: 'sarAPP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF), // purple
        ),
        useMaterial3: true,
      ),
      home: settings.onboardingComplete
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
