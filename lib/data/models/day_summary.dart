class DaySummary {
  final DateTime date;
  final int freeMinutes;
  final int studyMinutes;
  final int totalTasks;
  final int doneTasks;

  const DaySummary({
    required this.date,
    required this.freeMinutes,
    required this.studyMinutes,
    required this.totalTasks,
    required this.doneTasks,
  });

  bool get isEmpty => totalTasks == 0;

  bool get isComplete => totalTasks > 0 && doneTasks == totalTasks;

  double get ratio => totalTasks == 0 ? 0 : doneTasks / totalTasks;

  double get load =>
      freeMinutes == 0 ? 0 : (studyMinutes / freeMinutes).clamp(0.0, 1.0);
}
