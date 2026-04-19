import 'package:flutter/material.dart';

// Built-in emotions: value is what gets stored in old entries, label is the display string.
const builtInEmotions = [
  EmotionData('happy',     '😊 Happy',    Color(0xFFFFC107)),
  EmotionData('sad',       '😢 Sad',      Color(0xFF64B5F6)),
  EmotionData('angry',     '😤 Angry',    Color(0xFFEF5350)),
  EmotionData('anxious',   '😰 Anxious',  Color(0xFFFF8A65)),
  EmotionData('tired',     '😴 Tired',    Color(0xFF90A4AE)),
  EmotionData('energized', '⚡ Energized', Color(0xFF66BB6A)),
];

class EmotionData {
  final String value;
  final String label;
  final Color color;
  const EmotionData(this.value, this.label, this.color);
}

/// A row of toggle chips for selecting one or more emotions.
/// [options] is the user's custom list of emotion labels (display strings).
class EmotionTagSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final List<String> options;

  const EmotionTagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((label) {
        // New entries store the label as value; old entries stored the short key.
        final isSelected = selected.contains(label) ||
            selected.contains(_valueForLabel(label));
        final color = _colorForLabel(label);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: color.withAlpha(180),
          checkmarkColor: Colors.white,
          onSelected: (on) {
            final updated = List<String>.from(selected)
              // Remove both possible representations to avoid duplicates.
              ..remove(label)
              ..remove(_valueForLabel(label));
            if (on) updated.add(label);
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}

/// Returns the short key for a label if it's a built-in emotion, else the label itself.
String _valueForLabel(String label) =>
    builtInEmotions
        .firstWhere((e) => e.label == label,
            orElse: () => EmotionData(label, label, Colors.grey))
        .value;

Color _colorForLabel(String label) =>
    builtInEmotions
        .firstWhere((e) => e.label == label,
            orElse: () => const EmotionData('', '', Colors.grey))
        .color;

/// Returns the color for a stored emotion value (supports both old keys and new labels).
Color emotionColor(String value) {
  final byValue = builtInEmotions.where((e) => e.value == value);
  if (byValue.isNotEmpty) return byValue.first.color;
  final byLabel = builtInEmotions.where((e) => e.label == value);
  if (byLabel.isNotEmpty) return byLabel.first.color;
  return Colors.grey;
}

/// Returns the display label for a stored emotion value.
String emotionLabel(String value) {
  final byValue = builtInEmotions.where((e) => e.value == value);
  if (byValue.isNotEmpty) return byValue.first.label;
  return value; // custom emotions store label as value
}
