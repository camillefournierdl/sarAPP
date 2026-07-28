import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('About sarapp')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App identity
          Center(
            child: Column(
              children: [
                Icon(Icons.favorite_border, size: 56, color: primary),
                const SizedBox(height: 12),
                Text('sarapp',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('v0.1 · Free, open-source, and made with ❤️',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: outline)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Philosophy
          _AboutSection(
            icon: Icons.tune,
            title: 'Track what you choose',
            body:
                'sarapp lets you track different dimensions of your day. Everyone is different.'
                'You decide what dimensions matter to you. Enable or '
                'disable any module at any time in Settings. '
                'There is no required field.',
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.lock_outline,
            title: 'Your data, your device',
            body:
                'Everything you log stays on your phone. No account, no cloud '
                'sync, (currenty) no analytics. Your data is stored locally in a private '
                'database and can be exported to a CSV whenever you want.',
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.code,
            title: 'Free and open-source',
            body:
                'sarapp is free to use and its source code is open. You can '
                'inspect exactly what it does, contribute improvements, or '
                'adapt it for your own needs.',
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Data always stays on your device.',
              style: theme.textTheme.bodySmall?.copyWith(color: outline),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AboutSection(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
