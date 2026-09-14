import 'dart:convert';

import '../models/quiz_question.dart';
import 'topic_catalog.dart';

/// AI қайтарған JSON-ды сұрақтарға айналдырады және толық емесін сүзеді.
class QuizParser {
  const QuizParser._();

  /// Осыдан аз сұрақ қалса, тестті көрсетудің мәні жоқ.
  static const minQuestions = 2;

  static List<QuizQuestion> parse(
    String? answer, {
    required Topic topic,
    required bool isKz,
    required int count,
  }) {
    if (answer == null) return const [];
    final start = answer.indexOf('[');
    final end = answer.lastIndexOf(']');
    if (start == -1 || end <= start) return const [];

    try {
      final decoded = jsonDecode(answer.substring(start, end + 1));
      if (decoded is! List) return const [];

      final questions = <QuizQuestion>[];
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map) continue;

        final options = (item['options'] as List?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const <String>[];

        final question = QuizQuestion(
          id: '${topic.id}-ai-$i',
          topic: topic.name(isKz),
          prompt: (item['prompt'] as String? ?? '').trim(),
          options: options,
          correctIndex: optionIndex(item['correct'], options.length),
          explanation: (item['explanation'] as String? ?? '').trim(),
        );

        final duplicate = questions.any(
          (other) => other.prompt.toLowerCase() == question.prompt.toLowerCase(),
        );
        if (question.isValid && !duplicate) questions.add(question);
        if (questions.length == count) break;
      }
      return questions;
    } on FormatException {
      return const [];
    }
  }

  /// Модель индексті сан, бөлшек немесе жол түрінде қайтаруы мүмкін.
  static int optionIndex(Object? value, int length) {
    final index = switch (value) {
      final int number => number,
      final double number => number.round(),
      final String text => int.tryParse(text.trim()) ?? -1,
      _ => -1,
    };
    return index >= 0 && index < length ? index : -1;
  }
}
