import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/core/l10n.dart';
import 'package:smart_mentor/data/models/app_user.dart';
import 'package:smart_mentor/data/models/progress_stats.dart';
import 'package:smart_mentor/data/models/study_task.dart';
import 'package:smart_mentor/data/models/test_result.dart';
import 'package:smart_mentor/data/reports/progress_report.dart';

final now = DateTime(2026, 3, 10, 12);

AppUser buildUser() => AppUser(
      id: 'u1',
      name: 'Мұхтар Сұлтан',
      email: 'student@mail.com',
      grade: 8,
      olympiad: 'Информатика олимпиадасы',
      level: PrepLevel.middle,
      createdAt: now,
    );

StudyTask buildTask({
  required String title,
  TaskStatus status = TaskStatus.done,
  int spentSeconds = 0,
}) =>
    StudyTask(
      id: title,
      userId: 'u1',
      title: title,
      description: '',
      topic: 'Циклы',
      difficulty: TaskDifficulty.medium,
      durationMinutes: 30,
      date: now.subtract(const Duration(days: 1)),
      deadline: now,
      createdAt: now,
      status: status,
      spentSeconds: spentSeconds,
    );

void main() {
  final l = L10n(AppLang.ru);

  test('отчёт содержит данные ученика и общий результат', () {
    final report = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(
        completedTasks: 8,
        totalTasks: 10,
        studyMinutes: 300,
        streakDays: 4,
        activeDays: 6,
      ),
      tasks: [buildTask(title: 'Циклы: сумма чисел')],
      tests: const [],
      l: l,
      now: now,
    );

    expect(report, contains('Мұхтар Сұлтан'));
    expect(report, contains('Информатика олимпиадасы'));
    expect(report, contains('8 / 10'));
    expect(report, contains('80%'));
    expect(report, contains('Дней подряд: 4'));
  });

  test('без тестов раздел с результатами не печатается', () {
    final report = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(completedTasks: 1, totalTasks: 2),
      tasks: const [],
      tests: const [],
      l: l,
      now: now,
    );

    expect(report, isNot(contains('РЕЗУЛЬТАТЫ ТЕСТОВ')));
    expect(report, isNot(contains('Средний балл')));
  });

  test('слабые и сильные темы попадают в нужные разделы', () {
    final report = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(
        completedTasks: 5,
        totalTasks: 5,
        topicScores: {'Циклы': 0.4, 'Массивы': 0.9},
      ),
      tasks: const [],
      tests: const [],
      l: l,
      now: now,
    );

    final weakIndex = report.indexOf('ТРЕБУЕТ ВНИМАНИЯ');
    final strongIndex = report.indexOf('СИЛЬНЫЕ ТЕМЫ');
    expect(weakIndex, greaterThan(-1));
    expect(strongIndex, greaterThan(-1));
    expect(report.indexOf('Циклы — 40%'), greaterThan(weakIndex));
    expect(report.indexOf('Массивы — 90%'), greaterThan(strongIndex));
  });

  test('фактическое время показывается только когда есть замеры', () {
    final withoutTracking = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(studyMinutes: 120),
      tasks: const [],
      tests: const [],
      l: l,
      now: now,
    );
    expect(withoutTracking, isNot(contains('Фактически затрачено')));

    final withTracking = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(studyMinutes: 120, trackedMinutes: 90),
      tasks: const [],
      tests: const [],
      l: l,
      now: now,
    );
    expect(withTracking, contains('Фактически затрачено'));
    expect(withTracking, contains('75% от плана'));
  });

  test('в список попадают только выполненные задания', () {
    final report = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(),
      tasks: [
        buildTask(title: 'Готовое задание'),
        buildTask(title: 'Незакрытое задание', status: TaskStatus.pending),
      ],
      tests: const [],
      l: l,
      now: now,
    );

    expect(report, contains('Готовое задание'));
    expect(report, isNot(contains('Незакрытое задание')));
  });

  test('результаты тестов печатаются с датой и баллом', () {
    final report = ProgressReport.build(
      user: buildUser(),
      stats: const ProgressStats(testAverage: 0.7),
      tasks: const [],
      tests: [
        TestResult(
          id: 't1',
          userId: 'u1',
          topic: 'Массивы',
          score: 7,
          total: 10,
          date: DateTime(2026, 3, 9),
        ),
      ],
      l: l,
      now: now,
    );

    expect(report, contains('РЕЗУЛЬТАТЫ ТЕСТОВ'));
    expect(report, contains('09.03.2026'));
    expect(report, contains('Массивы — 7/10'));
  });
}
