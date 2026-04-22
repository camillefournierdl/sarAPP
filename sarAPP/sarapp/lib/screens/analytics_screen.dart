import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_module.dart';
import '../models/app_settings.dart';
import '../models/custom_module.dart';
import '../providers/analytics_provider.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final settings = context.watch<SettingsProvider>().settings;
    final entries = context.watch<EntriesProvider>().entries;

    Future<void> onFocusSelected(AnalyticsFocus f) =>
        context.read<AnalyticsProvider>().setFocus(f, entries, settings);

    Future<void> onTimeWindowChanged(AnalyticsTimeWindow w) async {
      final provider = context.read<AnalyticsProvider>();
      if (w == AnalyticsTimeWindow.custom) {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: analytics.customRange,
        );
        if (range == null) return;
        await provider.setTimeWindow(w, entries, settings, range: range);
      } else {
        await provider.setTimeWindow(w, entries, settings);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimeWindowBar(
            selected: analytics.timeWindow,
            onChanged: onTimeWindowChanged,
          ),
          const SizedBox(height: 16),
          _FocusModulePicker(
            settings: settings,
            currentFocus: analytics.focus,
            onFocusSelected: onFocusSelected,
          ),
          const SizedBox(height: 24),
          if (analytics.focus == null)
            const _EmptyState()
          else if (analytics.isComputing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (analytics.entryCount < 15)
            const _NotEnoughData()
          else if (analytics.results.isEmpty)
            const _NoAssociations()
          else ...[
            for (final r in analytics.results)
              _AssociationCard(
                result: r,
                focus: analytics.focus!,
                settings: settings,
              ),
            const SizedBox(height: 8),
            _TransparencyFooter(
              entryCount: analytics.entryCount,
              windowLabel: analytics.windowLabel(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Time window bar ────────────────────────────────────────────────────────────

class _TimeWindowBar extends StatelessWidget {
  final AnalyticsTimeWindow selected;
  final Future<void> Function(AnalyticsTimeWindow) onChanged;

  const _TimeWindowBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AnalyticsTimeWindow>(
        segments: const [
          ButtonSegment(value: AnalyticsTimeWindow.allTime, label: Text('All time')),
          ButtonSegment(value: AnalyticsTimeWindow.lastMonth, label: Text('Month')),
          ButtonSegment(value: AnalyticsTimeWindow.last3Months, label: Text('3 months')),
          ButtonSegment(value: AnalyticsTimeWindow.custom, label: Text('Custom')),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ── Focus module picker ────────────────────────────────────────────────────────

class _FocusModulePicker extends StatefulWidget {
  final AppSettings settings;
  final AnalyticsFocus? currentFocus;
  final Future<void> Function(AnalyticsFocus) onFocusSelected;

  const _FocusModulePicker({
    required this.settings,
    required this.currentFocus,
    required this.onFocusSelected,
  });

  @override
  State<_FocusModulePicker> createState() => _FocusModulePickerState();
}

class _FocusModulePickerState extends State<_FocusModulePicker> {
  int _step = 0;
  String? _pendingKey;

  // All enabled non-text module keys in display order
  List<String> _moduleKeys() => widget.settings.moduleOrder
      .where((key) =>
          widget.settings.isModuleEnabled(key) &&
          _responseTypeOf(key) != ResponseType.text)
      .toList();

  ResponseType? _responseTypeOf(String key) =>
      AppModule.forKey(key)?.responseType ??
      widget.settings.customModules
          .where((m) => m.id == key)
          .firstOrNull
          ?.responseType;

  bool _isScaleModule(String key) => _responseTypeOf(key) == ResponseType.scale;

  String _moduleLabel(String key) {
    final b = AppModule.forKey(key);
    if (b != null) return '${b.emoji} ${b.label}';
    final c = widget.settings.customModules.where((m) => m.id == key).firstOrNull;
    return c != null ? '${c.emoji} ${c.name}' : key;
  }

  List<String> _tagsFor(String key) {
    final b = AppModule.forKey(key);
    if (b != null) {
      switch (b.responseType) {
        case ResponseType.multiSelect:
        case ResponseType.singleSelect:
          return widget.settings.optionsFor(key);
        case ResponseType.conditional:
          final trigger = widget.settings.conditionalTriggerFor(key);
          final followups = widget.settings.conditionalOptionsFor(key);
          return [if (trigger.isNotEmpty) trigger, ...followups];
        default:
          return [];
      }
    }
    final c =
        widget.settings.customModules.where((m) => m.id == key).firstOrNull;
    if (c == null) return [];
    switch (c.responseType) {
      case ResponseType.multiSelect:
      case ResponseType.singleSelect:
        return c.options;
      case ResponseType.conditional:
        return [
          if (c.conditionalTrigger != null) c.conditionalTrigger!,
          ...c.conditionalOptions,
        ];
      default:
        return [];
    }
  }

  void _onModuleTap(String key) {
    if (_isScaleModule(key)) {
      widget.onFocusSelected(AnalyticsFocus(moduleKey: key));
    } else {
      setState(() {
        _pendingKey = key;
        _step = 1;
      });
    }
  }

  void _onTagTap(String tag) {
    widget.onFocusSelected(AnalyticsFocus(moduleKey: _pendingKey!, tag: tag));
    setState(() {
      _step = 0;
      _pendingKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (_step == 1 && _pendingKey != null) {
      final tags = _tagsFor(_pendingKey!);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _step = 0;
                  _pendingKey = null;
                }),
              ),
              Text(
                _moduleLabel(_pendingKey!),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pick a focus tag:', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags
                .map((tag) => ActionChip(
                      label: Text(tag),
                      onPressed: () => _onTagTap(tag),
                    ))
                .toList(),
          ),
        ],
      );
    }

    // Step 0: module list
    final keys = _moduleKeys();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Focus on:', style: theme.textTheme.labelLarge?.copyWith(color: primary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: keys.map((key) {
            final isSelected = widget.currentFocus?.moduleKey == key &&
                widget.currentFocus?.tag == null;
            return ActionChip(
              label: Text(_moduleLabel(key)),
              backgroundColor: isSelected ? primary.withAlpha(30) : null,
              side: isSelected
                  ? BorderSide(color: primary)
                  : null,
              onPressed: () => _onModuleTap(key),
            );
          }).toList(),
        ),
        if (widget.currentFocus?.tag != null) ...[
          const SizedBox(height: 4),
          Chip(
            label: Text(
              '${_moduleLabel(widget.currentFocus!.moduleKey)} › ${widget.currentFocus!.tag}',
            ),
            backgroundColor: primary.withAlpha(30),
            side: BorderSide(color: primary),
          ),
        ],
      ],
    );
  }
}

// ── Association card ───────────────────────────────────────────────────────────

class _AssociationCard extends StatelessWidget {
  final AssociationResult result;
  final AnalyticsFocus focus;
  final AppSettings settings;

  const _AssociationCard({
    required this.result,
    required this.focus,
    required this.settings,
  });

  String _moduleName(String key) =>
      AppModule.forKey(key)?.label ??
      settings.customModules.where((m) => m.id == key).firstOrNull?.name ??
      key;

  String _focusHighLabel() {
    final high = settings.labelHighFor(focus.moduleKey);
    if (high.isNotEmpty) return high;
    return _moduleName(focus.moduleKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isScaleFocus = focus.tag == null;
    final isScalePredictor = result.predictorTag == null;
    final predLabel = _moduleName(result.predictorKey);
    final lagStr = result.lag == AssociationLag.sameDay ? 'same day' : 'previous day';

    String title;
    if (isScaleFocus && isScalePredictor) {
      final dir = result.focusGroupValue >= result.comparisonGroupValue ? 'higher' : 'lower';
      title = '$predLabel tends to be $dir on ${_focusHighLabel()} days'
          ' (avg ${result.focusGroupValue.toStringAsFixed(1)}'
          ' vs ${result.comparisonGroupValue.toStringAsFixed(1)})';
    } else if (isScaleFocus && !isScalePredictor) {
      final fgPct = (result.focusGroupValue * 100).toStringAsFixed(0);
      final cgPct = (result.comparisonGroupValue * 100).toStringAsFixed(0);
      final verb = result.lag == AssociationLag.previousDay ? 'follow' : 'coincide with';
      title = '${_focusHighLabel()} days more often $verb'
          ' ${result.predictorTag} days ($fgPct% vs $cgPct%)';
    } else {
      // Event focus + scale predictor
      final dir = result.focusGroupValue >= result.comparisonGroupValue ? 'higher' : 'lower';
      title = '$predLabel was $dir on ${focus.tag} days'
          ' (avg ${result.focusGroupValue.toStringAsFixed(1)}'
          ' vs ${result.comparisonGroupValue.toStringAsFixed(1)})';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '· $lagStr',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            if (settings.analyticsNerdMode) ...[
              const SizedBox(height: 6),
              Text(
                '${result.testName}  ${result.effectSize.toStringAsFixed(2)}'
                ' · p = ${result.pValue.toStringAsFixed(3)}'
                ' · n = ${result.n}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (result.isLimitedData) ...[
              const SizedBox(height: 4),
              Text(
                'Based on limited data — treat with caution',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Placeholder states ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.insights, size: 56,
                color: theme.colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 16),
            Text('Pick a focus module above',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              "Choose what you want to understand and the app will show what it's associated with.",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Text(
          'Not enough data yet — keep logging!\n\nAt least 15 days of entries are needed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoAssociations extends StatelessWidget {
  const _NoAssociations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Text(
          'No significant associations found in this period.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Transparency footer ────────────────────────────────────────────────────────

class _TransparencyFooter extends StatelessWidget {
  final int entryCount;
  final String windowLabel;

  const _TransparencyFooter({
    required this.entryCount,
    required this.windowLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Based on $entryCount entries · $windowLabel · Indicative only',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
