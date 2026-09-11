class ProgressStats {
  final int completedTasks;
  final int totalTasks;
  final int studyMinutes;
  final int trackedMinutes;
  final int streakDays;
  final int activeDays;
  final double testAverage;
  final Map<String, double> topicScores;
  final List<int> weeklyCompleted;

  const ProgressStats({
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.studyMinutes = 0,
    this.trackedMinutes = 0,
    this.streakDays = 0,
    this.activeDays = 0,
    this.testAverage = 0,
    this.topicScores = const {},
    this.weeklyCompleted = const [0, 0, 0, 0, 0, 0, 0],
  });

  double get percentage => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  bool get hasTracked => trackedMinutes > 0;

  double get accuracy =>
      studyMinutes == 0 ? 0 : (trackedMinutes / studyMinutes).clamp(0.0, 2.0);

  List<MapEntry<String, double>> get weakTopics {
    final entries = topicScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.where((e) => e.value < 0.7).take(3).toList();
  }

  List<MapEntry<String, double>> get strongTopics {
    final entries = topicScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.where((e) => e.value >= 0.7).take(3).toList();
  }
}
