import 'package:flutter/material.dart';
import '../../l10n/l10n_helpers.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
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
                Text(l10n.aboutTagline,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: outline)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Philosophy
          _AboutSection(
            icon: Icons.tune,
            title: l10n.aboutTrackTitle,
            body: l10n.aboutTrackBody,
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.lock_outline,
            title: l10n.aboutDataTitle,
            body: l10n.aboutDataBody,
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.code,
            title: l10n.aboutOpenTitle,
            body: l10n.aboutOpenBody,
          ),
          const SizedBox(height: 20),
          _AboutSection(
            icon: Icons.health_and_safety_outlined,
            title: l10n.aboutMedicalTitle,
            body: l10n.aboutMedicalBody,
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              l10n.aboutFooter,
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
