class TestResult {
  final String id;
  final String userId;
  final String topic;
  final int score;
  final int total;
  final DateTime date;

  const TestResult({
    required this.id,
    required this.userId,
    required this.topic,
    required this.score,
    required this.total,
    required this.date,
  });

  double get percent => total == 0 ? 0 : score / total;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'topic': topic,
        'score': score,
        'total': total,
        'date': date.toIso8601String(),
      };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        id: json['id'] as String,
        userId: json['userId'] as String,
        topic: json['topic'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}
