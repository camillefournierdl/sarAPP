import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/cycle_phase_selector.dart';
import '../widgets/emotion_tag_selector.dart';
import 'log_entry_screen.dart';
import '../l10n/l10n_helpers.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>().entries;
    final isFemale =
        context.watch<SettingsProvider>().settings.isMenstruationTracking;

    if (entries.isEmpty) {
      return Center(
        child: Text(context.l10n.noEntriesYet),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _SwipeToDeleteBanner();
        }
        final e = entries[index - 1];
        return Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(context.l10n.deleteEntryTitle),
                content: Text(context.l10n.deleteEntryBody(DateFormat.yMMMMd()
                    .format(DateTime.parse(e.date))
                    .toLowerCase())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.cancel)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.l10n.delete,
                          style: const TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (_) {
            if (e.id != null) {
              context.read<EntriesProvider>().deleteEntry(e.id!);
            }
          },
          child: Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => LogEntryScreen(existing: e)),
              ),
              title: Text(
                DateFormat.yMMMEd().format(DateTime.parse(e.date)).toLowerCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (e.emotions.isNotEmpty)
                    Text(e.emotions
                        .map((em) => context.l10n.option(emotionLabel(em)))
                        .join(', ')),
                  if (isFemale && e.cyclePhase != null)
                    Text(context.l10n.cyclePhase(e.cyclePhase),
                        style: TextStyle(
                            color: cyclePhaseColor(e.cyclePhase))),
                  if (e.notes.isNotEmpty)
                    Text(
                      e.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}

class _SwipeToDeleteBanner extends StatelessWidget {
  const _SwipeToDeleteBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swipe_left_outlined, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.swipeToDelete,
              style: TextStyle(color: colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
