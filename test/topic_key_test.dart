import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/review_planner.dart';
import 'package:smart_mentor/data/ai/topic_catalog.dart';
import 'package:smart_mentor/data/models/study_task.dart';
import 'package:smart_mentor/data/reports/progress_report.dart';
import 'package:smart_mentor/core/l10n.dart';
import 'package:smart_mentor/data/models/app_user.dart';
import 'package:smart_mentor/data/models/progress_stats.dart';

void main() {
  final loops = TopicCatalog.byName('loops')!;

  test('ключ темы приводится к идентификатору каталога', () {
    expect(TopicCatalog.byName('Циклы')!.id, 'loops');
    expect(TopicCatalog.byName('Циклдер')!.id, 'loops');
    expect(TopicCatalog.byName('loops')!.id, 'loops');
  });

  test('подпись темы разворачивается обратно на нужный язык', () {
    expect(TopicCatalog.label('loops', false), 'Циклы');
    expect(TopicCatalog.label('loops', true), 'Циклдер');
  });

  test('неизвестный ключ показывается как есть', () {
    expect(TopicCatalog.label('Своя тема', false), 'Своя тема');
  });

  test('планировщик находит результат по идентификатору', () {
    final item = ReviewPlanner.statusFor(
      topic: loops,
      topicScores: const {'loops': 0.9},
      history: const [],
      date: DateTime(2026, 9, 16),
    );

    expect(item.score, 0.9);
    expect(item.interval, ReviewPlanner.strongIntervalDays);
  });

  test('охват тем считается по идентификаторам', () {
    final report = ProgressReport.build(
      user: AppUser(
        id: 'u',
        name: 'Ученик',
        email: 'a@b.c',
        level: PrepLevel.beginner,
        createdAt: DateTime(2026, 9, 16),
      ),
      stats: const ProgressStats(topicScores: {'loops': 0.4, 'arrays': 0.8}),
      tasks: const [],
      tests: const [],
      l: const L10n(AppLang.ru),
      now: DateTime(2026, 9, 16),
    );

    expect(report, contains('Охвачено тем: 2 / 9'));
    expect(report, contains('Циклы'));
    expect(report, isNot(contains('loops')));
  });

  test('история на двух языках относится к одной теме', () {
    StudyTask task(String topicName) => StudyTask(
          id: topicName,
          userId: 'u',
          title: 'задание',
          description: '',
          topic: topicName,
          difficulty: TaskDifficulty.easy,
          durationMinutes: 20,
          date: DateTime(2026, 9, 10),
          deadline: DateTime(2026, 9, 10),
          createdAt: DateTime(2026, 9, 10),
          status: TaskStatus.done,
        );

    for (final name in [loops.ru, loops.kk]) {
      final item = ReviewPlanner.statusFor(
        topic: loops,
        topicScores: const {'loops': 0.3},
        history: [task(name)],
        date: DateTime(2026, 9, 16),
      );
      expect(item.isNew, isFalse, reason: name);
      expect(item.lastSeen, DateTime(2026, 9, 10));
    }
  });
}
