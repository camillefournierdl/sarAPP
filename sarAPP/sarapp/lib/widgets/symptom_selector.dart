import 'package:flutter/material.dart';

const symptoms = [
  'cramps',
  'bloating',
  'headache',
  'fatigue',
  'mood swings',
  'breast tenderness',
  'back pain',
  'acne',
];

class SymptomSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const SymptomSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: symptoms.map((s) {
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
