import 'dart:math';

enum ResponseType { scale, multiSelect, singleSelect, text, conditional }

class CustomModule {
  final String id;
  final String name;
  final String emoji;
  final String question;
  final ResponseType responseType;
  final List<String> options;
  final String? conditionalTrigger;
  final String? conditionalQuestion;
  final List<String> conditionalOptions;
  final String labelLow;
  final String labelHigh;

  const CustomModule({
    required this.id,
    required this.name,
    required this.emoji,
    required this.question,
    required this.responseType,
    this.options = const [],
    this.conditionalTrigger,
    this.conditionalQuestion,
    this.conditionalOptions = const [],
    this.labelLow = '',
    this.labelHigh = '',
  });

  factory CustomModule.create({
    required String name,
    required String emoji,
    required String question,
    required ResponseType responseType,
    List<String> options = const [],
    String? conditionalTrigger,
    String? conditionalQuestion,
    List<String> conditionalOptions = const [],
    String labelLow = '',
    String labelHigh = '',
  }) =>
      CustomModule(
        id: _generateId(),
        name: name,
        emoji: emoji,
        question: question,
        responseType: responseType,
        options: options,
        conditionalTrigger: conditionalTrigger,
        conditionalQuestion: conditionalQuestion,
        conditionalOptions: conditionalOptions,
        labelLow: labelLow,
        labelHigh: labelHigh,
      );

  static String _generateId() {
    final r = Random.secure();
    String h(int max) => r.nextInt(max).toRadixString(16).padLeft(8, '0');
    return '${h(0xFFFFFFFF)}-${h(0xFFFF)}-4${h(0xFFF).substring(1)}'
        '-${(8 + r.nextInt(4)).toRadixString(16)}${h(0xFFF).substring(1)}'
        '-${h(0xFFFFFFFF)}${h(0xFFFF)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'question': question,
        'responseType': responseType.name,
        'options': options,
        if (conditionalTrigger != null) 'conditionalTrigger': conditionalTrigger,
        if (conditionalQuestion != null) 'conditionalQuestion': conditionalQuestion,
        if (conditionalOptions.isNotEmpty) 'conditionalOptions': conditionalOptions,
        if (labelLow.isNotEmpty) 'labelLow': labelLow,
        if (labelHigh.isNotEmpty) 'labelHigh': labelHigh,
      };

  factory CustomModule.fromJson(Map<String, dynamic> j) => CustomModule(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '',
        question: j['question'] as String,
        responseType: ResponseType.values.byName(j['responseType'] as String),
        options: List<String>.from(j['options'] as List? ?? []),
        conditionalTrigger: j['conditionalTrigger'] as String?,
        conditionalQuestion: j['conditionalQuestion'] as String?,
        conditionalOptions: List<String>.from(j['conditionalOptions'] as List? ?? []),
        labelLow: j['labelLow'] as String? ?? '',
        labelHigh: j['labelHigh'] as String? ?? '',
      );
}
