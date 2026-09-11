import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/pace_analyzer.dart';
import 'package:smart_mentor/data/models/study_task.dart';

StudyTask task({
  required int planned,
  required int spentSeconds,
  int daysAgo = 1,
}) {
  final now = DateTime(2026, 3, 10, 12);
  return StudyTask(
    id: 'id-$planned-$spentSeconds-$daysAgo',
    userId: 'user',
    title: 'task',
    description: '',
    topic: 'Циклы',
    difficulty: TaskDifficulty.medium,
    durationMinutes: planned,
    date: now.subtract(Duration(days: daysAgo)),
    deadline: now,
    createdAt: now,
    spentSeconds: spentSeconds,
  );
}

void main() {
  final now = DateTime(2026, 3, 10, 12);

  test('без замеров темп неизвестен', () {
    final report = PaceAnalyzer.analyze([], now);
    expect(report.pace, Pace.unknown);
    expect(report.measuredTasks, 0);
  });

  test('двух замеров недостаточно для вывода', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 30, spentSeconds: 3600),
      task(planned: 30, spentSeconds: 3600, daysAgo: 2),
    ], now);
    expect(report.pace, Pace.unknown);
  });

  test('стабильное превышение плана — медленный темп', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 30, spentSeconds: 2700),
      task(planned: 30, spentSeconds: 2700, daysAgo: 2),
      task(planned: 40, spentSeconds: 3600, daysAgo: 3),
    ], now);
    expect(report.pace, Pace.slow);
    expect(report.ratio, greaterThan(1.25));
  });

  test('заметно быстрее плана — быстрый темп', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 40, spentSeconds: 1200),
      task(planned: 40, spentSeconds: 1080, daysAgo: 2),
      task(planned: 30, spentSeconds: 900, daysAgo: 3),
    ], now);
    expect(report.pace, Pace.fast);
  });

  test('время близко к плану — темп в норме', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 30, spentSeconds: 1800),
      task(planned: 40, spentSeconds: 2400, daysAgo: 2),
      task(planned: 30, spentSeconds: 1980, daysAgo: 3),
    ], now);
    expect(report.pace, Pace.onTrack);
  });

  test('старые задания за окном не учитываются', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 30, spentSeconds: 3600, daysAgo: 20),
      task(planned: 30, spentSeconds: 3600, daysAgo: 30),
      task(planned: 30, spentSeconds: 3600, daysAgo: 40),
    ], now);
    expect(report.pace, Pace.unknown);
  });

  test('задания без замера времени игнорируются', () {
    final report = PaceAnalyzer.analyze([
      task(planned: 30, spentSeconds: 0),
      task(planned: 30, spentSeconds: 0, daysAgo: 2),
      task(planned: 30, spentSeconds: 2700, daysAgo: 3),
    ], now);
    expect(report.pace, Pace.unknown);
  });

  test('медленный темп ужимает бюджет, быстрый расширяет', () {
    const slow = PaceReport(pace: Pace.slow, ratio: 1.5, measuredTasks: 4);
    const fast = PaceReport(pace: Pace.fast, ratio: 0.6, measuredTasks: 4);
    expect(slow.adjustBudget(100), 80);
    expect(fast.adjustBudget(100), 115);
    expect(PaceReport.empty.adjustBudget(100), 100);
  });
}
