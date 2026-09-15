import '../models/study_task.dart';
import 'topic_catalog.dart';

class ReviewItem {
  final Topic topic;
  final DateTime? lastSeen;
  final double? score;
  final int interval;
  final int overdueDays;

  const ReviewItem({
    required this.topic,
    required this.lastSeen,
    required this.score,
    required this.interval,
    required this.overdueDays,
  });

  bool get isNew => lastSeen == null;
}

/// Тақырыпты қашан қайталау керегін есептейді. Нәтиже неғұрлым нашар болса,
/// тақырып соғұрлым тез оралады: әлсізі үш күнде, орташасы аптада,
/// меңгерілгені үш аптада.
class ReviewPlanner {
  const ReviewPlanner._();

  static const weakIntervalDays = 3;
  static const normalIntervalDays = 7;
  static const strongIntervalDays = 21;

  static const weakScore = 0.5;
  static const strongScore = 0.8;

  static int intervalFor(double? score) {
    if (score == null) return weakIntervalDays;
    if (score < weakScore) return weakIntervalDays;
    if (score < strongScore) return normalIntervalDays;
    return strongIntervalDays;
  }

  /// Қайталауға дайын тақырыптар: мерзімі неғұрлым көп өткені алда тұрады,
  /// бұрын мүлде қаралмағаны олардан кейін келеді.
  static List<ReviewItem> due({
    required List<Topic> pool,
    required Map<String, double> topicScores,
    required List<StudyTask> history,
    required DateTime date,
  }) {
    final items = <ReviewItem>[];

    for (final topic in pool) {
      final score = _scoreFor(topic, topicScores);
      final lastSeen = _lastSeen(topic, history, date);
      final interval = intervalFor(score);

      if (lastSeen == null) {
        items.add(ReviewItem(
          topic: topic,
          lastSeen: null,
          score: score,
          interval: interval,
          overdueDays: 0,
        ));
        continue;
      }

      final passed = date.difference(lastSeen).inDays;
      if (passed < interval) continue;

      items.add(ReviewItem(
        topic: topic,
        lastSeen: lastSeen,
        score: score,
        interval: interval,
        overdueDays: passed - interval,
      ));
    }

    items.sort((a, b) {
      if (a.isNew != b.isNew) return a.isNew ? 1 : -1;
      return b.overdueDays.compareTo(a.overdueDays);
    });
    return items;
  }

  static double? _scoreFor(Topic topic, Map<String, double> scores) =>
      scores[topic.kk] ?? scores[topic.ru] ?? scores[topic.id];

  /// Тақырып соңғы рет қашан кездескені: орындалған тапсырмалар ғана есепке алынады,
  /// өйткені ашылмаған тапсырма қайталау болып саналмайды.
  static DateTime? _lastSeen(
    Topic topic,
    List<StudyTask> history,
    DateTime date,
  ) {
    DateTime? last;
    for (final task in history) {
      if (!task.isDone) continue;
      if (task.topic != topic.kk && task.topic != topic.ru) continue;
      if (task.date.isAfter(date)) continue;
      if (last == null || task.date.isAfter(last)) last = task.date;
    }
    return last;
  }
}
