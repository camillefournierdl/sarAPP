import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_module.dart';
import '../models/custom_module.dart';
import '../models/entry.dart';
import '../providers/entries_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chip_selector.dart';
import '../widgets/emotion_tag_selector.dart';
import '../widgets/scale_slider.dart';
import '../models/app_settings.dart';

class LogEntryScreen extends StatefulWidget {
  final Entry? existing;
  final String? date;

  const LogEntryScreen({super.key, this.existing, this.date});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  late String _date;
  late List<String> _emotions;
  String? _cyclePhase;
  late bool _periodStart;
  late bool _periodEnd;
  late List<String> _symptoms;
  int? _happinessScore;
  int? _sleepScore;
  int? _stressScore;
  int? _weatherScore;
  String? _workDay;
  late List<String> _foods;
  late List<String> _sports;
  late List<String> _leisure;
  String? _healthStatus;
  late List<String> _sickTags;
  late TextEditingController _notesController;
  int? _libidoScore;
  String? _hadSex;
  int? _waterGlasses;
  Map<String, dynamic> _customData = {};
  final Map<String, TextEditingController> _customTextControllers = {};
  int _pageIndex = 0;

  static const int _modulesPerPage = 3;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ??
        widget.date ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    _emotions = List.from(e?.emotions ?? []);
    _cyclePhase = e?.cyclePhase;
    _periodStart = e?.periodStart ?? false;
    _periodEnd = e?.periodEnd ?? false;
    _symptoms = List.from(e?.symptoms ?? []);
    _happinessScore = e?.happinessScore;
    _sleepScore = e?.sleepScore;
    _stressScore = e?.stressScore;
    _weatherScore = e?.weatherScore;
    _workDay = e?.workDay;
    _foods = List.from(e?.foods ?? []);
    _sports = List.from(e?.sports ?? []);
    _leisure = List.from(e?.leisure ?? []);
    _healthStatus = e?.healthStatus;
    _sickTags = List.from(e?.sickTags ?? []);
    _notesController = TextEditingController(text: e?.notes ?? '');
    _libidoScore = e?.libidoScore;
    _hadSex = e?.hadSex;
    _waterGlasses = e?.waterGlasses;
    _customData = Map.from(e?.customData ?? {});
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final ctrl in _customTextControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String _appBarTitle() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_date == today) return widget.existing == null ? 'Log today' : 'Edit today';
    return DateFormat('MMM d, yyyy').format(DateTime.parse(_date));
  }

  Future<void> _save() async {
    for (final e in _customTextControllers.entries) {
      _customData[e.key] = e.value.text.trim();
    }
    _customData.removeWhere((_, v) {
      if (v == null || v == '') return true;
      if (v is Map) return v['value'] == null;
      return false;
    });
    final settings = context.read<SettingsProvider>().settings;
    final answeredModules =
        settings.moduleOrder.where(settings.isModuleEnabled).toSet();
    final entry = Entry.create(
      date: _date,
      emotions: _emotions,
      cyclePhase: _cyclePhase,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      symptoms: _symptoms,
      happinessScore: _happinessScore,
      sleepScore: _sleepScore,
      stressScore: _stressScore,
      weatherScore: _weatherScore,
      workDay: _workDay,
      foods: _foods,
      sports: _sports,
      leisure: _leisure,
      healthStatus: _healthStatus,
      sickTags: _sickTags,
      notes: _notesController.text.trim(),
      libidoScore: _libidoScore,
      hadSex: _hadSex,
      waterGlasses: _waterGlasses,
      customData: Map.from(_customData),
      answeredModules: answeredModules,
    );
    await context.read<EntriesProvider>().saveEntry(entry);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  /// Returns the widgets for a built-in module. Returns null if the module
  /// should be hidden (e.g., symptoms when menstruation tracking is off).
  List<Widget>? _buildBuiltinModule(
      AppModule m, AppSettings settings, bool isFemale) {
    if (m.menstruationOnly && !isFemale) return null;

    Widget child;
    switch (m.key) {
      case 'happiness':
        child = ScaleSlider(
          value: _happinessScore,
          onChanged: (v) => setState(() => _happinessScore = v),
          labelLow: settings.labelLowFor('happiness'),
          labelHigh: settings.labelHighFor('happiness'),
        );
      case 'emotions':
        child = EmotionTagSelector(
          options: settings.optionsFor('emotions'),
          selected: _emotions,
          onChanged: (v) => setState(() => _emotions = v),
        );
      case 'sleep':
        child = ScaleSlider(
          value: _sleepScore,
          onChanged: (v) => setState(() => _sleepScore = v),
          labelLow: settings.labelLowFor('sleep'),
          labelHigh: settings.labelHighFor('sleep'),
        );
      case 'stress':
        child = ScaleSlider(
          value: _stressScore,
          onChanged: (v) => setState(() => _stressScore = v),
          labelLow: settings.labelLowFor('stress'),
          labelHigh: settings.labelHighFor('stress'),
        );
      case 'weather':
        child = ScaleSlider(
          value: _weatherScore,
          onChanged: (v) => setState(() => _weatherScore = v),
          labelLow: settings.labelLowFor('weather'),
          labelHigh: settings.labelHighFor('weather'),
        );
      case 'health':
        final primaryOpts = settings.optionsFor('health');
        final trigger = settings.conditionalTriggerFor('health');
        final followupQ = settings.conditionalQuestionFor('health');
        final followupOpts = settings.conditionalOptionsFor('health');
        return [
          _Section(
            title: settings.questionFor('health', m.description),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: primaryOpts.map((opt) => ChoiceChip(
                label: Text(opt),
                selected: _healthStatus == opt,
                onSelected: (on) => setState(() {
                  _healthStatus = on ? opt : null;
                  if (_healthStatus != trigger) _sickTags = [];
                }),
              )).toList(),
            ),
          ),
          if (_healthStatus == trigger && followupOpts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: followupQ.isNotEmpty ? followupQ : 'Follow-up',
              child: ChipSelector(
                options: followupOpts,
                selected: _sickTags,
                onChanged: (v) => setState(() => _sickTags = v),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ];
      case 'work':
        final workOpts = settings.optionsFor('work');
        child = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: workOpts.map((opt) => ChoiceChip(
            label: Text(opt),
            selected: _workDay == opt,
            onSelected: (on) => setState(() => _workDay = on ? opt : null),
          )).toList(),
        );
      case 'sports':
        child = ChipSelector(
          options: settings.optionsFor('sports'),
          selected: _sports,
          onChanged: (v) => setState(() => _sports = v),
        );
      case 'leisure':
        child = ChipSelector(
          options: settings.optionsFor('leisure'),
          selected: _leisure,
          onChanged: (v) => setState(() => _leisure = v),
        );
      case 'food':
        child = ChipSelector(
          options: settings.optionsFor('food'),
          selected: _foods,
          onChanged: (v) => setState(() => _foods = v),
        );
      case 'symptoms':
        child = ChipSelector(
          options: settings.optionsFor('symptoms'),
          selected: _symptoms,
          onChanged: (v) => setState(() => _symptoms = v),
        );
      case 'notes':
        child = TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Anything else on your mind…',
            border: OutlineInputBorder(),
          ),
        );
      case 'libido':
        child = ScaleSlider(
          value: _libidoScore,
          onChanged: (v) => setState(() => _libidoScore = v),
          labelLow: settings.labelLowFor('libido'),
          labelHigh: settings.labelHighFor('libido'),
        );
      case 'sex':
        final sexOpts = settings.optionsFor('sex');
        child = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sexOpts.map((opt) => ChoiceChip(
            label: Text(opt),
            selected: _hadSex == opt,
            onSelected: (on) => setState(() => _hadSex = on ? opt : null),
          )).toList(),
        );
      case 'water':
        child = ScaleSlider(
          value: _waterGlasses,
          onChanged: (v) => setState(() => _waterGlasses = v),
          labelLow: settings.labelLowFor('water'),
          labelHigh: settings.labelHighFor('water'),
        );
      default:
        return null;
    }

    return [
      _Section(
        title: settings.questionFor(m.key, m.description),
        child: child,
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildCustomModuleInput(CustomModule m) {
    switch (m.responseType) {
      case ResponseType.scale:
        final val = _customData[m.id] as int?;
        return ScaleSlider(
          value: val,
          onChanged: (v) => setState(() => _customData[m.id] = v),
          labelLow: m.labelLow,
          labelHigh: m.labelHigh,
        );
      case ResponseType.multiSelect:
        final selected = List<String>.from(_customData[m.id] as List? ?? []);
        return ChipSelector(
          options: m.options,
          selected: selected,
          onChanged: (v) => setState(() => _customData[m.id] = v),
        );
      case ResponseType.singleSelect:
        final current = _customData[m.id] as String?;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: m.options
              .map((opt) => ChoiceChip(
                    label: Text(opt),
                    selected: current == opt,
                    onSelected: (on) =>
                        setState(() => _customData[m.id] = on ? opt : null),
                  ))
              .toList(),
        );
      case ResponseType.text:
        final ctrl = _customTextControllers.putIfAbsent(
          m.id,
          () => TextEditingController(
              text: _customData[m.id] as String? ?? ''),
        );
        return TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (v) => _customData[m.id] = v,
        );
      case ResponseType.conditional:
        final data = (_customData[m.id] as Map?)?.cast<String, dynamic>() ?? {};
        final primary = data['value'] as String?;
        final followup = List<String>.from(data['followup'] as List? ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: m.options.map((opt) => ChoiceChip(
                label: Text(opt),
                selected: primary == opt,
                onSelected: (on) => setState(() {
                  final val = on ? opt : null;
                  _customData[m.id] = {
                    'value': val,
                    'followup': val == m.conditionalTrigger ? followup : [],
                  };
                }),
              )).toList(),
            ),
            if (primary == m.conditionalTrigger &&
                m.conditionalOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (m.conditionalQuestion != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    m.conditionalQuestion!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ChipSelector(
                options: m.conditionalOptions,
                selected: followup,
                onChanged: (v) => setState(() {
                  _customData[m.id] = {'value': primary, 'followup': v};
                }),
              ),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final isFemale = settings.isMenstruationTracking;
    final theme = Theme.of(context);

    // Build ordered list of enabled module keys
    final orderedKeys = settings.moduleOrder
        .where(settings.isModuleEnabled)
        .toList();

    if (orderedKeys.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_appBarTitle())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune,
                    size: 56,
                    color: theme.colorScheme.primary.withAlpha(120)),
                const SizedBox(height: 20),
                Text('No modules enabled',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Enable at least one module in Settings to start logging.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Go to Settings'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Chunk the enabled keys into pages of _modulesPerPage
    final pages = <List<String>>[];
    for (var i = 0; i < orderedKeys.length; i += _modulesPerPage) {
      pages.add(orderedKeys.sublist(
          i, (i + _modulesPerPage).clamp(0, orderedKeys.length)));
    }

    final currentPage = _pageIndex.clamp(0, pages.length - 1);
    final isLastPage = currentPage == pages.length - 1;

    final pageWidgets = <Widget>[];
    for (final key in pages[currentPage]) {
      final builtin = AppModule.forKey(key);
      if (builtin != null) {
        final widgets = _buildBuiltinModule(builtin, settings, isFemale);
        if (widgets != null) pageWidgets.addAll(widgets);
        continue;
      }
      final customMatches = settings.customModules.where((m) => m.id == key);
      if (customMatches.isNotEmpty) {
        final m = customMatches.first;
        pageWidgets.addAll([
          _Section(title: m.question, child: _buildCustomModuleInput(m)),
          const SizedBox(height: 16),
        ]);
      }
    }

    return PopScope(
      canPop: currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _pageIndex = currentPage - 1);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        actions: [
          if (isLastPage)
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(_date)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (pages.length > 1)
                Text(
                  '${currentPage + 1} / ${pages.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ...pageWidgets,
          const SizedBox(height: 16),
          if (pages.length > 1)
            Row(
              children: [
                if (currentPage > 0)
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _pageIndex = currentPage - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                const Spacer(),
                if (!isLastPage)
                  FilledButton.icon(
                    onPressed: () =>
                        setState(() => _pageIndex = currentPage + 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    iconAlignment: IconAlignment.end,
                  ),
                if (isLastPage)
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    iconAlignment: IconAlignment.end,
                  ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    ),
    );
  }
}


class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
