import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cycle_service.dart';
import '../services/notification_service.dart';
import '../widgets/cycle_phase_selector.dart';
import '../widgets/emotion_tag_selector.dart';
import 'analytics_screen.dart';
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

  @override
  void initState() {
    super.initState();
    // Handle cold-start notification tap: pendingLogDate was set before runApp
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final date = NotificationService.pendingLogDate;
      if (date == null) return;
      NotificationService.pendingLogDate = null;
      _navigateToLogEntry(date);
    });
  }

  void _navigateToLogEntry(String date) {
    final existing = context.read<EntriesProvider>().getByDate(date);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => existing != null
          ? LogEntryScreen(existing: existing)
          : LogEntryScreen(date: date),
    ));
  }

  static const _tabs = [
    _DashboardTab(),
    HistoryScreen(),
    CalendarScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_tab.clamp(0, _tabs.length - 1)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.clamp(0, _tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.insights), label: 'Analytics'),
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
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    final entries = context.watch<EntriesProvider>().entries;
    final todayEntry = context.watch<EntriesProvider>().getByDate(today);
    final yesterdayEntry = context.watch<EntriesProvider>().getByDate(yesterday);
    final settings = context.watch<SettingsProvider>().settings;
    final isFemale = settings.isMenstruationTracking;
    final theme = Theme.of(context);

    // Determine cycle baseline: prefer settings, fall back to most recent logged start
    final loggedBaseline = entries
        .where((e) => e.periodStart)
        .map((e) => e.date)
        .fold<String?>(null, (best, d) =>
            best == null || d.compareTo(best) > 0 ? d : best);
    final cycleBaseline = settings.lastPeriodStart ?? loggedBaseline;

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

        // ── Cycle info card (female mode, any baseline available) ────────
        if (isFemale && cycleBaseline != null)
          _CycleInfoCard(
              lastPeriodStart: cycleBaseline,
              entries: entries),

        const SizedBox(height: 16),

        // Yesterday catch-up prompt
        if (yesterdayEntry == null) ...[
          _CatchUpCard(date: yesterday),
          const SizedBox(height: 8),
        ],

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
  final List<Entry> entries;
  const _CycleInfoCard(
      {required this.lastPeriodStart, required this.entries});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final phase = CycleService.todayPhase(lastPeriodStart,
        entries: entries, showHighFertility: settings.showHighFertility);
    final day = CycleService.dayOfCycle(lastPeriodStart, entries: entries);
    final daysLeft =
        CycleService.daysUntilNextPeriod(lastPeriodStart, entries: entries);
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

class _CatchUpCard extends StatelessWidget {
  final String date;
  const _CatchUpCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE').format(DateTime.parse(date));
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.history_edu),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No log for $label — want to catch up?'),
            ),
            TextButton(
              onPressed: () {
                final existing =
                    context.read<EntriesProvider>().getByDate(date);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => existing != null
                      ? LogEntryScreen(existing: existing)
                      : LogEntryScreen(date: date),
                ));
              },
              child: const Text('Log it'),
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
