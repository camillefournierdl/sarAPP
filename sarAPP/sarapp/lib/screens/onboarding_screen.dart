import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _select(BuildContext context, {required bool menstruationTracking}) async {
    // SarApp watches settings and swaps home to HomeScreen automatically —
    // no manual navigation needed here.
    await context.read<SettingsProvider>().setOnboardingComplete(menstruationTracking: menstruationTracking);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'sarAPP',
                style: theme.textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your mood and wellbeing.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              Text(
                'Do you want to track your menstrual cycle?',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _ModeCard(
                icon: Icons.favorite,
                title: 'Yes — track menstruation',
                subtitle: 'Mood + cycle phases, period dates & symptoms',
                color: const Color(0xFFE53935),
                onTap: () => _select(context, menstruationTracking: true),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.mood,
                title: 'No — mood only',
                subtitle: 'Happiness, emotions, sleep, food & activity',
                color: const Color(0xFF7C4DFF),
                onTap: () => _select(context, menstruationTracking: false),
              ),
              const SizedBox(height: 32),
              Text(
                'You can change this later in Settings.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(40),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
