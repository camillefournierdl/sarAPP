import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/custom_module.dart';
import '../../models/app_module.dart';
import '../../providers/settings_provider.dart';
import 'module_edit_screen.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  void _onReorder(
      int oldIndex, int newIndex, List<String> visibleKeys, AppSettings settings,
      BuildContext context) {
    if (newIndex > oldIndex) newIndex--;
    final newVisible = List<String>.from(visibleKeys);
    final moved = newVisible.removeAt(oldIndex);
    newVisible.insert(newIndex, moved);
    // Reconstruct full order keeping hidden modules at their sorted positions
    final fullOrder = List<String>.from(settings.moduleOrder);
    final visibleIndices = visibleKeys
        .map(fullOrder.indexOf)
        .toList()
      ..sort();
    for (var i = 0; i < visibleIndices.length; i++) {
      fullOrder[visibleIndices[i]] = newVisible[i];
    }
    context.read<SettingsProvider>().update(
          settings.copyWith(moduleOrder: fullOrder));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    final visibleKeys = settings.moduleOrder.where((key) {
      final builtin = AppModule.forKey(key);
      if (builtin != null) {
        return !builtin.menstruationOnly || settings.isMenstruationTracking;
      }
      return settings.customModules.any((m) => m.id == key);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Questionnaire modules')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModuleEditScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Icon(Icons.drag_indicator_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag (press long) to reorder. Tap ✏️ to customise.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: visibleKeys.length,
              onReorder: (oldIdx, newIdx) =>
                  _onReorder(oldIdx, newIdx, visibleKeys, settings, context),
              itemBuilder: (ctx, index) {
                final key = visibleKeys[index];
                final builtin = AppModule.forKey(key);
                final custom = builtin == null
                    ? settings.customModules
                        .where((m) => m.id == key)
                        .cast<CustomModule?>()
                        .firstWhere((_) => true, orElse: () => null)
                    : null;

                final emojiStr =
                    builtin?.emoji ?? (custom?.emoji.isNotEmpty == true ? custom!.emoji : null);
                final label = builtin?.label ?? custom?.name ?? key;
                final subtitle = builtin != null
                    ? (settings.customModuleQuestions[key] ?? builtin.description)
                    : (custom?.question ?? '');

                return ListTile(
                  key: Key(key),
                  leading: emojiStr != null
                      ? Text(emojiStr, style: const TextStyle(fontSize: 20))
                      : const Icon(Icons.tune),
                  title: Text(label),
                  subtitle: Text(subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit module',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ModuleEditScreen(moduleKey: key),
                          ),
                        ),
                      ),
                      Switch(
                        value: settings.isModuleEnabled(key),
                        onChanged: (_) => context
                            .read<SettingsProvider>()
                            .update(settings.withModuleToggled(key)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomizeModulesScreen extends StatelessWidget {
  const CustomizeModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Customize modules')),
      body: ListView(
        children: settings.moduleOrder.map((key) {
          final builtin = AppModule.forKey(key);
          if (builtin != null) {
            return ListTile(
              leading: Text(builtin.emoji,
                  style: const TextStyle(fontSize: 20)),
              title: Text(builtin.label),
              subtitle: Text(
                settings.customModuleQuestions[key] ?? builtin.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ModuleEditScreen(moduleKey: key),
                ),
              ),
            );
          }
          final customMatches =
              settings.customModules.where((m) => m.id == key);
          if (customMatches.isEmpty) return const SizedBox.shrink();
          final custom = customMatches.first;
          return ListTile(
            leading: custom.emoji.isNotEmpty
                ? Text(custom.emoji, style: const TextStyle(fontSize: 20))
                : const Icon(Icons.tune),
            title: Text(custom.name),
            subtitle: Text(custom.question,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ModuleEditScreen(moduleKey: key),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
