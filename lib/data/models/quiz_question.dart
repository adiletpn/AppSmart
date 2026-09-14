class QuizQuestion {
  final String id;
  final String topic;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  bool get isValid =>
      prompt.trim().isNotEmpty &&
      options.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < options.length;

  String get correctOption => options[correctIndex];

  bool isCorrect(int index) => index == correctIndex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        id: json['id'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            const [],
        correctIndex: json['correctIndex'] as int? ?? 0,
        explanation: json['explanation'] as String? ?? '',
      );
}
