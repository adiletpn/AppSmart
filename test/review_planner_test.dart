import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/review_planner.dart';
import 'package:smart_mentor/data/ai/topic_catalog.dart';
import 'package:smart_mentor/data/models/study_task.dart';

StudyTask done(String topic, DateTime date) => StudyTask(
      id: '$topic-${date.day}',
      userId: 'u',
      title: 'задание',
      description: '',
      topic: topic,
      difficulty: TaskDifficulty.medium,
      durationMinutes: 30,
      date: date,
      deadline: date,
      createdAt: date,
      status: TaskStatus.done,
    );

void main() {
  final today = DateTime(2026, 9, 15);
  final loops = TopicCatalog.byName('loops')!;
  final arrays = TopicCatalog.byName('arrays')!;
  final pool = [loops, arrays];

  List<ReviewItem> due({
    Map<String, double> scores = const {},
    List<StudyTask> history = const [],
  }) =>
      ReviewPlanner.due(
        pool: pool,
        topicScores: scores,
        history: history,
        date: today,
      );

  test('интервал зависит от результата по теме', () {
    expect(ReviewPlanner.intervalFor(0.2), ReviewPlanner.weakIntervalDays);
    expect(ReviewPlanner.intervalFor(0.65), ReviewPlanner.normalIntervalDays);
    expect(ReviewPlanner.intervalFor(0.95), ReviewPlanner.strongIntervalDays);
    expect(ReviewPlanner.intervalFor(null), ReviewPlanner.weakIntervalDays);
  });

  test('нетронутая тема считается новой и не просроченной', () {
    final items = due();

    expect(items.length, 2);
    expect(items.every((i) => i.isNew), isTrue);
    expect(items.every((i) => i.overdueDays == 0), isTrue);
  });

  test('слабая тема возвращается через три дня', () {
    final scores = {loops.ru: 0.3};

    final early = due(
      scores: scores,
      history: [done(loops.ru, today.subtract(const Duration(days: 2)))],
    );
    expect(early.where((i) => i.topic.id == 'loops'), isEmpty);

    final ready = due(
      scores: scores,
      history: [done(loops.ru, today.subtract(const Duration(days: 3)))],
    );
    expect(ready.any((i) => i.topic.id == 'loops'), isTrue);
  });

  test('освоенная тема не возвращается раньше трёх недель', () {
    final scores = {loops.ru: 0.9};

    final week = due(
      scores: scores,
      history: [done(loops.ru, today.subtract(const Duration(days: 7)))],
    );
    expect(week.where((i) => i.topic.id == 'loops'), isEmpty);

    final ready = due(
      scores: scores,
      history: [done(loops.ru, today.subtract(const Duration(days: 21)))],
    );
    expect(ready.any((i) => i.topic.id == 'loops'), isTrue);
  });

  test('самая просроченная тема идёт первой', () {
    final items = due(
      scores: {loops.ru: 0.3, arrays.ru: 0.3},
      history: [
        done(loops.ru, today.subtract(const Duration(days: 4))),
        done(arrays.ru, today.subtract(const Duration(days: 30))),
      ],
    );

    expect(items.first.topic.id, 'arrays');
    expect(items.first.overdueDays, 27);
    expect(items.last.topic.id, 'loops');
  });

  test('просроченная тема идёт раньше новой', () {
    final items = due(
      scores: {loops.ru: 0.3},
      history: [done(loops.ru, today.subtract(const Duration(days: 10)))],
    );

    expect(items.first.topic.id, 'loops');
    expect(items.first.isNew, isFalse);
    expect(items.last.isNew, isTrue);
  });

  test('невыполненное задание не считается повторением', () {
    final history = [
      done(loops.ru, today).copyWith(status: TaskStatus.missed),
    ];

    expect(due(scores: {loops.ru: 0.3}, history: history).first.isNew, isTrue);
  });

  test('тема узнаётся на обоих языках', () {
    final byKk = due(
      scores: {loops.kk: 0.9},
      history: [done(loops.kk, today.subtract(const Duration(days: 7)))],
    );

    expect(byKk.where((i) => i.topic.id == 'loops'), isEmpty);
  });

  test('задания из будущего не учитываются', () {
    final items = due(
      scores: {loops.ru: 0.3},
      history: [done(loops.ru, today.add(const Duration(days: 5)))],
    );

    expect(items.firstWhere((i) => i.topic.id == 'loops').isNew, isTrue);
  });
}
