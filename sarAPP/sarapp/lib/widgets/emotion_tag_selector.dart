import 'package:flutter/material.dart';

// Each emotion has a label and a color.
const emotions = [
  EmotionData('happy', '😊 Happy', Color(0xFFFFC107)),
  EmotionData('sad', '😢 Sad', Color(0xFF64B5F6)),
  EmotionData('angry', '😤 Angry', Color(0xFFEF5350)),
  EmotionData('anxious', '😰 Anxious', Color(0xFFFF8A65)),
  EmotionData('tired', '😴 Tired', Color(0xFF90A4AE)),
  EmotionData('energized', '⚡ Energized', Color(0xFF66BB6A)),
];

class EmotionData {
  final String value;
  final String label;
  final Color color;
  const EmotionData(this.value, this.label, this.color);
}

/// A row of toggle chips for selecting one or more emotions.
class EmotionTagSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const EmotionTagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emotions.map((e) {
        final isSelected = selected.contains(e.value);
        return FilterChip(
          label: Text(e.label),
          selected: isSelected,
          selectedColor: e.color.withAlpha(180),
          checkmarkColor: Colors.white,
          onSelected: (on) {
            final updated = List<String>.from(selected);
            if (on) {
              updated.add(e.value);
            } else {
              updated.remove(e.value);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}

/// Returns the color for a given emotion value (used in charts).
Color emotionColor(String value) =>
    emotions.firstWhere((e) => e.value == value,
        orElse: () => const EmotionData('', '', Colors.grey)).color;

/// Returns the display label for a given emotion value.
String emotionLabel(String value) =>
    emotions.firstWhere((e) => e.value == value,
        orElse: () => EmotionData('', value, Colors.grey)).label;
