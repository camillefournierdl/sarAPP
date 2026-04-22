import 'package:flutter/material.dart';

class ScaleSlider extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String labelLow;
  final String labelHigh;

  const ScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelLow = '',
    this.labelHigh = '',
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        if (labelLow.isNotEmpty) Text(labelLow, style: const TextStyle(fontSize: 16)),
        Expanded(
          child: Slider(
            value: (value ?? 5).toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: value == null ? '—' : '$value',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        if (labelHigh.isNotEmpty) Text(labelHigh, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            value == null ? '—' : '$value / 10',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value == null ? Colors.grey : primary,
            ),
          ),
        ),
      ],
    );
  }
}
