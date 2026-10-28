import 'package:flutter/material.dart';
import '../l10n/l10n_helpers.dart';

class ChipSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const ChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          label: Text(context.l10n.option(opt)),
          selected: isSelected,
          onSelected: (on) {
            final updated = List<String>.from(selected);
            if (on) {
              updated.add(opt);
            } else {
              updated.remove(opt);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
