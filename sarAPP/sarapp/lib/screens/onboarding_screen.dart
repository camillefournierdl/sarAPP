import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class _UseCase {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool menstruationTracking;
  final Set<String> modules;

  const _UseCase({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.menstruationTracking,
    required this.modules,
  });
}

const _useCases = [
  _UseCase(
    icon: Icons.favorite,
    color: Color(0xFFE53935),
    title: 'Menstrual health',
    subtitle: 'Cycle phases, symptoms, mood & sleep',
    menstruationTracking: true,
    modules: {'happiness', 'emotions', 'sleep', 'health', 'symptoms', 'notes'},
  ),
  _UseCase(
    icon: Icons.self_improvement,
    color: Color(0xFF7C4DFF),
    title: 'Mood & wellbeing',
    subtitle: 'Emotions, happiness, sleep & mental health',
    menstruationTracking: false,
    modules: {'happiness', 'emotions', 'sleep', 'health', 'notes'},
  ),
  _UseCase(
    icon: Icons.directions_run,
    color: Color(0xFF00897B),
    title: 'Active lifestyle',
    subtitle: 'Sports, food, hydration & energy',
    menstruationTracking: false,
    modules: {'happiness', 'sleep', 'sports', 'leisure', 'food', 'water', 'health'},
  ),
  _UseCase(
    icon: Icons.track_changes,
    color: Color(0xFFF57C00),
    title: 'General wellness',
    subtitle: 'Mood, activity, food, weather & more',
    menstruationTracking: false,
    modules: {
      'happiness', 'emotions', 'sleep', 'weather', 'health',
      'work', 'sports', 'leisure', 'food', 'notes',
    },
  ),
];

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _select(BuildContext context, _UseCase useCase) async {
    await context.read<SettingsProvider>().setOnboardingComplete(
          menstruationTracking: useCase.menstruationTracking,
          enabledModules: useCase.modules,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'sarapp',
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'What do you want to track?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick the option that fits best — you can always customise modules in Settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _useCases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _UseCaseCard(useCase: _useCases[i], onTap: () => _select(context, _useCases[i])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UseCaseCard extends StatelessWidget {
  final _UseCase useCase;
  final VoidCallback onTap;

  const _UseCaseCard({required this.useCase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: useCase.color.withAlpha(30),
                child: Icon(useCase.icon, color: useCase.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(useCase.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(useCase.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
