import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/custom_module.dart';
import '../../models/app_module.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/l10n_helpers.dart';

class ModuleEditScreen extends StatefulWidget {
  final String? moduleKey; // null = create new custom module

  const ModuleEditScreen({super.key, this.moduleKey});

  @override
  State<ModuleEditScreen> createState() => _ModuleEditScreenState();
}

class _ModuleEditScreenState extends State<ModuleEditScreen> {
  AppModule? _builtin;
  CustomModule? _custom;

  late TextEditingController _questionCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _emojiCtrl;
  late TextEditingController _optionAddCtrl;
  late TextEditingController _conditionalTriggerCtrl;
  late TextEditingController _conditionalQuestionCtrl;
  late TextEditingController _conditionalOptionAddCtrl;
  late TextEditingController _labelLowCtrl;
  late TextEditingController _labelHighCtrl;
  late ResponseType _responseType;
  late List<String> _options;
  late List<String> _conditionalOptions;
  bool _isDirty = false;
  bool _didInitText = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;

    if (widget.moduleKey != null) {
      _builtin = AppModule.forKey(widget.moduleKey!);
      if (_builtin == null) {
        final customMatches =
            settings.customModules.where((m) => m.id == widget.moduleKey);
        _custom = customMatches.isEmpty ? null : customMatches.first;
      }
    }

    if (_builtin != null) {
      // Default question / follow-up text is translated, so it's filled in
      // didChangeDependencies once localizations are available.
      _questionCtrl = TextEditingController(
          text: settings.customModuleQuestions[_builtin!.key]);
      _nameCtrl = TextEditingController();
      _emojiCtrl = TextEditingController();
      _responseType = _builtin!.responseType;
      _options = List.from(settings.optionsFor(_builtin!.key));
      _conditionalTriggerCtrl = TextEditingController(
          text: settings.conditionalTriggerFor(_builtin!.key));
      _conditionalQuestionCtrl = TextEditingController(
          text: settings.moduleConditionalQuestion[_builtin!.key]);
      _conditionalOptions = List.from(settings.conditionalOptionsFor(_builtin!.key));
      _labelLowCtrl = TextEditingController(text: settings.labelLowFor(_builtin!.key));
      _labelHighCtrl = TextEditingController(text: settings.labelHighFor(_builtin!.key));
    } else if (_custom != null) {
      _questionCtrl = TextEditingController(text: _custom!.question);
      _nameCtrl = TextEditingController(text: _custom!.name);
      _emojiCtrl = TextEditingController(text: _custom!.emoji);
      _responseType = _custom!.responseType;
      _options = List.from(_custom!.options);
      _conditionalTriggerCtrl = TextEditingController(text: _custom!.conditionalTrigger ?? '');
      _conditionalQuestionCtrl = TextEditingController(text: _custom!.conditionalQuestion ?? '');
      _conditionalOptions = List.from(_custom!.conditionalOptions);
      _labelLowCtrl = TextEditingController(text: _custom!.labelLow);
      _labelHighCtrl = TextEditingController(text: _custom!.labelHigh);
    } else {
      _questionCtrl = TextEditingController();
      _nameCtrl = TextEditingController();
      _emojiCtrl = TextEditingController();
      _responseType = ResponseType.scale;
      _options = [];
      _conditionalTriggerCtrl = TextEditingController();
      _conditionalQuestionCtrl = TextEditingController();
      _conditionalOptions = [];
      _labelLowCtrl = TextEditingController();
      _labelHighCtrl = TextEditingController();
    }
    _optionAddCtrl = TextEditingController();
    _conditionalOptionAddCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitText) return;
    _didInitText = true;
    final l10n = context.l10n;
    if (_builtin != null) {
      if (_questionCtrl.text.isEmpty) {
        _questionCtrl.text = l10n.moduleDescription(_builtin!);
      }
      if (_conditionalQuestionCtrl.text.isEmpty) {
        _conditionalQuestionCtrl.text =
            l10n.conditionalQuestion(_builtin!.conditionalQuestion);
      }
    }
    // The trigger is stored as the raw option value; show its display label.
    _conditionalTriggerCtrl.text = l10n.option(_conditionalTriggerCtrl.text);

    // Listeners are added after the initial text so filling it isn't an edit.
    for (final ctrl in [
      _questionCtrl, _nameCtrl, _emojiCtrl,
      _conditionalTriggerCtrl, _conditionalQuestionCtrl,
      _labelLowCtrl, _labelHighCtrl,
    ]) {
      ctrl.addListener(_markDirty);
    }
  }

  /// Maps a trigger typed as a display label back to the stored option value.
  String _rawTrigger(String text) => _options.firstWhere(
      (o) => context.l10n.option(o) == text,
      orElse: () => text);

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _optionAddCtrl.dispose();
    _conditionalTriggerCtrl.dispose();
    _conditionalQuestionCtrl.dispose();
    _conditionalOptionAddCtrl.dispose();
    _labelLowCtrl.dispose();
    _labelHighCtrl.dispose();
    super.dispose();
  }

  bool get _hasOptionList =>
      _responseType == ResponseType.multiSelect ||
      _responseType == ResponseType.singleSelect ||
      _responseType == ResponseType.conditional;

  void _addOption() {
    final v = _optionAddCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _options.add(v);
      _optionAddCtrl.clear();
      _isDirty = true;
    });
  }

  void _addConditionalOption() {
    final v = _conditionalOptionAddCtrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _conditionalOptions.add(v);
      _conditionalOptionAddCtrl.clear();
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>().settings;

    if (_builtin != null) {
      final question = _questionCtrl.text.trim();
      final questionMap =
          Map<String, String>.from(settings.customModuleQuestions);
      if (question.isEmpty ||
          question == _builtin!.description ||
          question == context.l10n.moduleDescription(_builtin!)) {
        questionMap.remove(_builtin!.key);
      } else {
        questionMap[_builtin!.key] = question;
      }
      var updated = settings.copyWith(customModuleQuestions: questionMap);

      if (_hasOptionList) {
        final opts = Map<String, List<String>>.from(settings.moduleOptions);
        opts[_builtin!.key] = List.from(_options);
        updated = updated.copyWith(moduleOptions: opts);

        // Mark as user-modified so optionsFor() uses the stored value going
        // forward, preserving the user's customization across app updates.
        final modified = Set<String>.from(settings.userModifiedModuleOptions)
          ..add(_builtin!.key);
        updated = updated.copyWith(userModifiedModuleOptions: modified);
      }

      if (_responseType == ResponseType.scale) {
        final ll = _labelLowCtrl.text.trim();
        final lh = _labelHighCtrl.text.trim();
        final low = Map<String, String>.from(settings.moduleLabelLow);
        final high = Map<String, String>.from(settings.moduleLabelHigh);
        (ll.isEmpty || ll == _builtin!.labelLow) ? low.remove(_builtin!.key) : low[_builtin!.key] = ll;
        (lh.isEmpty || lh == _builtin!.labelHigh) ? high.remove(_builtin!.key) : high[_builtin!.key] = lh;
        updated = updated.copyWith(moduleLabelLow: low, moduleLabelHigh: high);
      }

      if (_responseType == ResponseType.conditional) {
        final trigger = _rawTrigger(_conditionalTriggerCtrl.text.trim());
        final condQ = _conditionalQuestionCtrl.text.trim();
        final defaultCondQ = _builtin!.conditionalQuestion;

        final condOpts = Map<String, List<String>>.from(settings.moduleConditionalOptions);
        condOpts[_builtin!.key] = List.from(_conditionalOptions);
        updated = updated.copyWith(moduleConditionalOptions: condOpts);

        final triggers = Map<String, String>.from(settings.moduleConditionalTrigger);
        (trigger.isEmpty || trigger == _builtin!.conditionalTrigger)
            ? triggers.remove(_builtin!.key)
            : triggers[_builtin!.key] = trigger;
        updated = updated.copyWith(moduleConditionalTrigger: triggers);

        final condQs = Map<String, String>.from(settings.moduleConditionalQuestion);
        (condQ.isEmpty ||
                condQ == defaultCondQ ||
                condQ == context.l10n.conditionalQuestion(defaultCondQ))
            ? condQs.remove(_builtin!.key)
            : condQs[_builtin!.key] = condQ;
        updated = updated.copyWith(moduleConditionalQuestion: condQs);
      }

      await context.read<SettingsProvider>().update(updated);
    } else if (_custom != null) {
      final name = _nameCtrl.text.trim();
      final question = _questionCtrl.text.trim();
      if (name.isEmpty || question.isEmpty) return;
      final trigger = _rawTrigger(_conditionalTriggerCtrl.text.trim());
      final condQuestion = _conditionalQuestionCtrl.text.trim();
      final updatedModule = CustomModule(
        id: _custom!.id,
        name: name,
        emoji: _emojiCtrl.text.trim(),
        question: question,
        responseType: _responseType,
        options: List.from(_options),
        conditionalTrigger: trigger.isEmpty ? null : trigger,
        conditionalQuestion: condQuestion.isEmpty ? null : condQuestion,
        conditionalOptions: List.from(_conditionalOptions),
        labelLow: _labelLowCtrl.text.trim(),
        labelHigh: _labelHighCtrl.text.trim(),
      );
      await context.read<SettingsProvider>().update(settings.copyWith(
            customModules: settings.customModules
                .map((m) => m.id == _custom!.id ? updatedModule : m)
                .toList(),
          ));
    } else {
      final name = _nameCtrl.text.trim();
      final question = _questionCtrl.text.trim();
      if (name.isEmpty || question.isEmpty) return;
      final trigger = _rawTrigger(_conditionalTriggerCtrl.text.trim());
      final condQuestion = _conditionalQuestionCtrl.text.trim();
      final newModule = CustomModule.create(
        name: name,
        emoji: _emojiCtrl.text.trim(),
        question: question,
        responseType: _responseType,
        options: List.from(_options),
        conditionalTrigger: trigger.isEmpty ? null : trigger,
        conditionalQuestion: condQuestion.isEmpty ? null : condQuestion,
        conditionalOptions: List.from(_conditionalOptions),
        labelLow: _labelLowCtrl.text.trim(),
        labelHigh: _labelHighCtrl.text.trim(),
      );
      await context.read<SettingsProvider>().update(settings.copyWith(
            customModules: [...settings.customModules, newModule],
            enabledModules: {...settings.enabledModules, newModule.id},
            moduleOrder: [...settings.moduleOrder, newModule.id],
          ));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _deleteModule() async {
    final settings = context.read<SettingsProvider>().settings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.removeModuleTitle(_custom!.name)),
        content: Text(context.l10n.removeModuleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // ignore: use_build_context_synchronously
    await context.read<SettingsProvider>().update(settings.copyWith(
          customModules:
              settings.customModules.where((m) => m.id != _custom!.id).toList(),
          enabledModules: Set<String>.from(settings.enabledModules)
            ..remove(_custom!.id),
          moduleOrder:
              settings.moduleOrder.where((k) => k != _custom!.id).toList(),
        ));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final title = _builtin != null
        ? '${_builtin!.emoji} ${l10n.moduleLabel(_builtin!)}'
        : _custom != null
            ? l10n.editModule
            : l10n.newModule;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l10n.discardTitle),
            content: Text(l10n.discardBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.keepEditing),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.discard),
              ),
            ],
          ),
        );
        if (leave == true && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_builtin == null) ...[
            Row(children: [
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _emojiCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.iconLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.moduleNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _questionCtrl,
            decoration: InputDecoration(
              labelText: l10n.questionLabel,
              helperText: _builtin != null ? l10n.clearToRestoreDefault : null,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text(l10n.responseType, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ResponseType.values.map((rt) {
              final label = switch (rt) {
                ResponseType.scale => l10n.rtScale,
                ResponseType.multiSelect => l10n.rtMultiSelect,
                ResponseType.singleSelect => l10n.rtSingleSelect,
                ResponseType.text => l10n.rtText,
                ResponseType.conditional => l10n.rtConditional,
              };
              if (_builtin != null) {
                return rt == _responseType
                    ? Chip(label: Text(label))
                    : const SizedBox.shrink();
              }
              return ChoiceChip(
                label: Text(label),
                selected: _responseType == rt,
                onSelected: (_) => setState(() {
                  _responseType = rt;
                  _isDirty = true;
                  if (rt != ResponseType.multiSelect &&
                      rt != ResponseType.singleSelect &&
                      rt != ResponseType.conditional) {
                    _options.clear();
                  }
                  if (rt != ResponseType.conditional) {
                    _conditionalOptions.clear();
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_responseType == ResponseType.scale) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _labelLowCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.lowLabel,
                    hintText: _builtin?.labelLow.isNotEmpty == true
                        ? _builtin!.labelLow
                        : '0',
                    helperText: l10n.lowLabelHelper,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _labelHighCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.highLabel,
                    hintText: _builtin?.labelHigh.isNotEmpty == true
                        ? _builtin!.labelHigh
                        : '10',
                    helperText: l10n.highLabelHelper,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (_hasOptionList) ...[
            Text(
              _responseType == ResponseType.conditional
                  ? l10n.primaryOptions
                  : l10n.answerOptions,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ..._options.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.option(opt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() { _options.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _optionAddCtrl,
              hint: l10n.optionHint,
              onAdd: _addOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_responseType == ResponseType.conditional) ...[
            TextField(
              controller: _conditionalTriggerCtrl,
              decoration: InputDecoration(
                labelText: l10n.triggerOption,
                hintText: l10n.triggerOptionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditionalQuestionCtrl,
              decoration: InputDecoration(
                labelText: l10n.followupQuestionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.followupOptions, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ..._conditionalOptions.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.option(opt)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() { _conditionalOptions.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _conditionalOptionAddCtrl,
              hint: l10n.followupOptionHint,
              onAdd: _addConditionalOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_custom != null) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text(l10n.removeModule,
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: Text(l10n.pastResponsesKept),
              onTap: _deleteModule,
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _AddItemRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;

  const _AddItemRow({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAdd,
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );
  }
}
