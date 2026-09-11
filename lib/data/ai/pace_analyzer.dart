import '../models/study_task.dart';

enum Pace { unknown, fast, onTrack, slow }

class PaceReport {
  final Pace pace;
  final double ratio;
  final int measuredTasks;

  const PaceReport({
    required this.pace,
    required this.ratio,
    required this.measuredTasks,
  });

  static const empty =
      PaceReport(pace: Pace.unknown, ratio: 1, measuredTasks: 0);

  int adjustBudget(int budget) => switch (pace) {
        Pace.slow => (budget * 0.8).round(),
        Pace.fast => (budget * 1.15).round(),
        _ => budget,
      };
}

class PaceAnalyzer {
  const PaceAnalyzer._();

  static const _minTasks = 3;
  static const _windowDays = 7;

  static PaceReport analyze(List<StudyTask> history, DateTime now) {
    final measured = history.where((task) {
      if (task.spentMinutes <= 0 || task.durationMinutes <= 0) return false;
      final age = now.difference(task.date).inDays;
      return age >= 0 && age <= _windowDays;
    }).toList();

    if (measured.length < _minTasks) return PaceReport.empty;

    final planned =
        measured.fold<int>(0, (total, task) => total + task.durationMinutes);
    final spent =
        measured.fold<int>(0, (total, task) => total + task.spentMinutes);
    final ratio = spent / planned;

    return PaceReport(
      pace: ratio > 1.25
          ? Pace.slow
          : ratio < 0.75
              ? Pace.fast
              : Pace.onTrack,
      ratio: ratio,
      measuredTasks: measured.length,
    );
  }
}
