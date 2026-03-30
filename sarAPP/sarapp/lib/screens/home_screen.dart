import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cycle_service.dart';
import '../widgets/cycle_phase_selector.dart';
import '../widgets/emotion_tag_selector.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'log_entry_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _tabs = [
    _DashboardTab(),
    HistoryScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sarAPP'),
        centerTitle: true,
      ),
      body: _tabs[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ── Dashboard tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEntry = context.watch<EntriesProvider>().getByDate(today);
    final settings = context.watch<SettingsProvider>().settings;
    final isFemale = settings.isFemaleMode;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting
        Text(
          _greeting(),
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 16),

        // ── Cycle info card (female mode, baseline set) ──────────────────
        if (isFemale && settings.lastPeriodStart != null)
          _CycleInfoCard(lastPeriodStart: settings.lastPeriodStart!),

        const SizedBox(height: 16),

        // Today's card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: todayEntry == null
                ? Column(
                    children: [
                      const Text("You haven't logged today yet."),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Log today'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const LogEntryScreen()),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text("Today's log",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => LogEntryScreen(
                                      existing: todayEntry)),
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      if (todayEntry.emotions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: todayEntry.emotions.map((em) {
                            return Chip(
                              label: Text(emotionLabel(em),
                                  style: const TextStyle(fontSize: 12)),
                              backgroundColor:
                                  emotionColor(em).withAlpha(60),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                      if (isFemale && todayEntry.cyclePhase != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cyclePhaseColor(todayEntry.cyclePhase),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(cyclePhaseLabel(todayEntry.cyclePhase)),
                          ],
                        ),
                      ],
                      if (todayEntry.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(todayEntry.notes,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
          ),
        ),

        // Recent entries preview
        const SizedBox(height: 24),
        Text('Recent', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _RecentList(),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 18) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
}

// ── Cycle info card ───────────────────────────────────────────────────────────

class _CycleInfoCard extends StatelessWidget {
  final String lastPeriodStart;
  const _CycleInfoCard({required this.lastPeriodStart});

  @override
  Widget build(BuildContext context) {
    final phase = CycleService.todayPhase(lastPeriodStart);
    final day = CycleService.dayOfCycle(lastPeriodStart);
    final daysLeft = CycleService.daysUntilNextPeriod(lastPeriodStart);
    final color = cyclePhaseColor(phase);

    return Card(
      color: color.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day $day — ${cyclePhaseLabel(phase)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    daysLeft == 1
                        ? 'Next period predicted tomorrow'
                        : 'Next period in $daysLeft days',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries =
        context.watch<EntriesProvider>().entries.take(5).toList();
    if (entries.isEmpty) {
      return const Text('No past entries yet.',
          style: TextStyle(fontStyle: FontStyle.italic));
    }
    return Column(
      children: entries.map((e) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(DateFormat('EEE, MMM d').format(DateTime.parse(e.date))),
          subtitle: e.emotions.isNotEmpty
              ? Text(e.emotions.map(emotionLabel).join(', '))
              : null,
          trailing: e.cyclePhase != null
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cyclePhaseColor(e.cyclePhase),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => LogEntryScreen(existing: e)),
          ),
        );
      }).toList(),
    );
  }
}
