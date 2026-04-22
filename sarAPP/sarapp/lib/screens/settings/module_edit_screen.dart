import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/custom_module.dart';
import '../../models/app_module.dart';
import '../../providers/settings_provider.dart';

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
      _questionCtrl = TextEditingController(
          text: settings.customModuleQuestions[_builtin!.key] ?? _builtin!.description);
      _nameCtrl = TextEditingController();
      _emojiCtrl = TextEditingController();
      _responseType = _builtin!.responseType;
      _options = List.from(settings.optionsFor(_builtin!.key));
      _conditionalTriggerCtrl = TextEditingController(
          text: settings.conditionalTriggerFor(_builtin!.key));
      _conditionalQuestionCtrl = TextEditingController(
          text: settings.conditionalQuestionFor(_builtin!.key));
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

    for (final ctrl in [
      _questionCtrl, _nameCtrl, _emojiCtrl,
      _conditionalTriggerCtrl, _conditionalQuestionCtrl,
      _labelLowCtrl, _labelHighCtrl,
    ]) {
      ctrl.addListener(_markDirty);
    }
  }

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
      if (question.isEmpty || question == _builtin!.description) {
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
        final trigger = _conditionalTriggerCtrl.text.trim();
        final condQ = _conditionalQuestionCtrl.text.trim();

        final condOpts = Map<String, List<String>>.from(settings.moduleConditionalOptions);
        condOpts[_builtin!.key] = List.from(_conditionalOptions);
        updated = updated.copyWith(moduleConditionalOptions: condOpts);

        final triggers = Map<String, String>.from(settings.moduleConditionalTrigger);
        (trigger.isEmpty || trigger == _builtin!.conditionalTrigger)
            ? triggers.remove(_builtin!.key)
            : triggers[_builtin!.key] = trigger;
        updated = updated.copyWith(moduleConditionalTrigger: triggers);

        final condQs = Map<String, String>.from(settings.moduleConditionalQuestion);
        (condQ.isEmpty || condQ == _builtin!.conditionalQuestion)
            ? condQs.remove(_builtin!.key)
            : condQs[_builtin!.key] = condQ;
        updated = updated.copyWith(moduleConditionalQuestion: condQs);
      }

      await context.read<SettingsProvider>().update(updated);
    } else if (_custom != null) {
      final name = _nameCtrl.text.trim();
      final question = _questionCtrl.text.trim();
      if (name.isEmpty || question.isEmpty) return;
      final trigger = _conditionalTriggerCtrl.text.trim();
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
      final trigger = _conditionalTriggerCtrl.text.trim();
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
        title: Text('Remove "${_custom!.name}"?'),
        content: const Text(
          'This module will be removed from your questionnaire. '
          'Past responses are kept silently in your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
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

    final title = _builtin != null
        ? '${_builtin!.emoji} ${_builtin!.label}'
        : _custom != null
            ? 'Edit module'
            : 'New module';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('You have unsaved edits. Discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
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
          TextButton(onPressed: _save, child: const Text('Save')),
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
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Module name *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _questionCtrl,
            decoration: InputDecoration(
              labelText: 'Question',
              helperText: _builtin != null ? 'Clear to restore default' : null,
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text('Response type', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ResponseType.values.map((rt) {
              final label = switch (rt) {
                ResponseType.scale => '0–10 Scale',
                ResponseType.multiSelect => 'Multi-select',
                ResponseType.singleSelect => 'Single-select',
                ResponseType.text => 'Free text',
                ResponseType.conditional => 'Conditional',
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
                    labelText: 'Low label',
                    hintText: _builtin?.labelLow.isNotEmpty == true
                        ? _builtin!.labelLow
                        : '0',
                    helperText: 'Emoji or text for the low end',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _labelHighCtrl,
                  decoration: InputDecoration(
                    labelText: 'High label',
                    hintText: _builtin?.labelHigh.isNotEmpty == true
                        ? _builtin!.labelHigh
                        : '10',
                    helperText: 'Emoji or text for the high end',
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
                  ? 'Primary options'
                  : 'Answer options',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ..._options.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() { _options.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _optionAddCtrl,
              hint: 'e.g. 😊 Happy',
              onAdd: _addOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_responseType == ResponseType.conditional) ...[
            TextField(
              controller: _conditionalTriggerCtrl,
              decoration: const InputDecoration(
                labelText: 'Trigger option',
                hintText: 'Which option reveals the follow-up?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditionalQuestionCtrl,
              decoration: const InputDecoration(
                labelText: 'Follow-up question (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Follow-up options', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ..._conditionalOptions.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() { _conditionalOptions.remove(opt); _isDirty = true; }),
                  ),
                )),
            _AddItemRow(
              controller: _conditionalOptionAddCtrl,
              hint: 'Add a follow-up option',
              onAdd: _addConditionalOption,
            ),
            const SizedBox(height: 16),
          ],
          if (_custom != null) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              title: Text('Remove module',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Past responses are kept in your data'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
