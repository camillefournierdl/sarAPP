import 'dart:math';

enum ResponseType { scale, multiSelect, singleSelect, text, conditional }

class CustomModule {
  final String id;
  final String name;
  final String emoji;
  final String question;
  final ResponseType responseType;
  final List<String> options;
  /// For conditional type: which primary option reveals the follow-up.
  final String? conditionalTrigger;
  /// For conditional type: the follow-up question label.
  final String? conditionalQuestion;
  /// For conditional type: follow-up multi-select options.
  final List<String> conditionalOptions;

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
      );
}
