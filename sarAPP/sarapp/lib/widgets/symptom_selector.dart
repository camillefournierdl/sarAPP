import 'package:flutter/material.dart';

class SymptomSelector extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const SymptomSelector({
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
      children: options.map((s) {
        final isSelected = selected.contains(s);
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (on) {
            final updated = List<String>.from(selected);
            if (on) {
              updated.add(s);
            } else {
              updated.remove(s);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
