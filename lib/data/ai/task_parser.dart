import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/time_utils.dart';
import '../models/study_task.dart';

/// AI қайтарған JSON-ды тапсырмаларға айналдырады: атауы, шарты, мысалдары,
/// бағыты және талдауы. Толық емес жазбалар алынып тасталады.
class TaskParser {
  const TaskParser._();

  static const _uuid = Uuid();

  static const minMinutes = 10;
  static const maxMinutes = 120;

  static List<StudyTask> parse(
    String? answer, {
    required String userId,
    required DateTime date,
    required int budget,
  }) {
    if (answer == null) return const [];
    final start = answer.indexOf('[');
    final end = answer.lastIndexOf(']');
    if (start == -1 || end <= start) return const [];

    try {
      final decoded = jsonDecode(answer.substring(start, end + 1));
      if (decoded is! List) return const [];

      final day = TimeUtils.dayStart(date);
      final tasks = <StudyTask>[];
      var spent = 0;

      for (final item in decoded) {
        if (item is! Map) continue;
        final title = (item['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;

        final minutes = _minutes(item['minutes']);
        if (spent + minutes > budget && tasks.isNotEmpty) break;

        tasks.add(StudyTask(
          id: _uuid.v4(),
          userId: userId,
          title: title,
          description: (item['description'] as String? ?? '').trim(),
          topic: (item['topic'] as String? ?? '').trim(),
          difficulty: TaskDifficulty.values.firstWhere(
            (d) => d.name == item['difficulty'],
            orElse: () => TaskDifficulty.medium,
          ),
          durationMinutes: minutes,
          date: day,
          deadline: day.add(const Duration(hours: 23, minutes: 59)),
          createdAt: DateTime.now(),
          statement: (item['statement'] as String? ?? '').trim(),
          examples: _examples(item['examples']),
          hint: (item['hint'] as String? ?? '').trim(),
          solution: (item['solution'] as String? ?? '').trim(),
        ));
        spent += minutes;
      }
      return tasks;
    } on Exception {
      return const [];
    }
  }

  /// Модель уақытты сан, бөлшек немесе жол түрінде қайтаруы мүмкін.
  static int _minutes(Object? value) {
    final raw = switch (value) {
      final num number => number.round(),
      final String text => int.tryParse(text.trim()) ?? 30,
      _ => 30,
    };
    return raw.clamp(minMinutes, maxMinutes);
  }

  /// Кіріс не шығысы бос мысал көрсетілмейді.
  static List<TaskExample> _examples(Object? value) {
    if (value is! List) return const [];

    final examples = <TaskExample>[];
    for (final item in value) {
      if (item is! Map) continue;
      final input = (item['input'] ?? '').toString().trim();
      final output = (item['output'] ?? '').toString().trim();
      if (input.isEmpty || output.isEmpty) continue;
      examples.add(TaskExample(input: input, output: output));
      if (examples.length == 3) break;
    }
    return examples;
  }
}
