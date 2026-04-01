import 'package:flutter/material.dart';

const cyclePhases = [
  _Phase('menstruation',  'Menstruation',      Color(0xFFE53935)),
  _Phase('follicular',    'Follicular',         Color(0xFF43A047)),
  _Phase('high_fertility','Higher fertility',   Color(0xFFFFA726)), // orange
  _Phase('ovulation',     'Ovulation',          Color(0xFFFDD835)),
  _Phase('luteal',        'Luteal',             Color(0xFF8E24AA)),
];

class _Phase {
  final String value;
  final String label;
  final Color color;
  const _Phase(this.value, this.label, this.color);
}

/// Four-option cycle phase selector. Tapping the current selection deselects.
class CyclePhaseSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const CyclePhaseSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cyclePhases.map((p) {
        final isSelected = selected == p.value;
        return ChoiceChip(
          label: Text(p.label),
          selected: isSelected,
          selectedColor: p.color.withAlpha(200),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
          onSelected: (_) => onChanged(isSelected ? null : p.value),
        );
      }).toList(),
    );
  }
}

Color cyclePhaseColor(String? value) {
  if (value == null) return Colors.grey;
  return cyclePhases
      .firstWhere((p) => p.value == value,
          orElse: () => const _Phase('', '', Colors.grey))
      .color;
}

String cyclePhaseLabel(String? value) {
  if (value == null) return '—';
  return cyclePhases
      .firstWhere((p) => p.value == value,
          orElse: () => _Phase('', value, Colors.grey))
      .label;
}
