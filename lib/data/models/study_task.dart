class TaskExample {
  final String input;
  final String output;

  const TaskExample({required this.input, required this.output});

  Map<String, dynamic> toJson() => {'input': input, 'output': output};

  factory TaskExample.fromJson(Map<String, dynamic> json) => TaskExample(
        input: json['input'] as String? ?? '',
        output: json['output'] as String? ?? '',
      );
}

enum TaskDifficulty { easy, medium, hard }

extension TaskDifficultyX on TaskDifficulty {
  int get weight => switch (this) {
        TaskDifficulty.easy => 1,
        TaskDifficulty.medium => 2,
        TaskDifficulty.hard => 3,
      };
}

enum TaskStatus { pending, inProgress, done, missed }

class StudyTask {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String topic;
  final TaskDifficulty difficulty;
  final int durationMinutes;
  final DateTime date;
  final DateTime deadline;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? startTime;
  final int spentSeconds;
  final DateTime? startedAt;
  final String statement;
  final List<TaskExample> examples;
  final String hint;
  final String solution;

  const StudyTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.topic,
    required this.difficulty,
    required this.durationMinutes,
    required this.date,
    required this.deadline,
    this.status = TaskStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.startTime,
    this.spentSeconds = 0,
    this.startedAt,
    this.statement = '',
    this.examples = const [],
    this.hint = '',
    this.solution = '',
  });

  bool get isDone => status == TaskStatus.done;

  bool get hasStatement => statement.trim().isNotEmpty;

  bool get hasHint => hint.trim().isNotEmpty;

  bool get hasSolution => solution.trim().isNotEmpty;

  bool get isRunning => startedAt != null;

  int get elapsedSeconds => startedAt == null
      ? spentSeconds
      : spentSeconds + DateTime.now().difference(startedAt!).inSeconds;

  int get spentMinutes => (elapsedSeconds / 60).round();

  StudyTask copyWith({
    String? title,
    String? description,
    String? topic,
    TaskDifficulty? difficulty,
    int? durationMinutes,
    DateTime? date,
    DateTime? deadline,
    TaskStatus? status,
    DateTime? completedAt,
    String? startTime,
    int? spentSeconds,
    DateTime? startedAt,
    String? statement,
    List<TaskExample>? examples,
    String? hint,
    String? solution,
    bool clearCompletedAt = false,
    bool clearStartedAt = false,
  }) =>
      StudyTask(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        topic: topic ?? this.topic,
        difficulty: difficulty ?? this.difficulty,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        date: date ?? this.date,
        deadline: deadline ?? this.deadline,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
        startTime: startTime ?? this.startTime,
        spentSeconds: spentSeconds ?? this.spentSeconds,
        startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
        statement: statement ?? this.statement,
        examples: examples ?? this.examples,
        hint: hint ?? this.hint,
        solution: solution ?? this.solution,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'topic': topic,
        'difficulty': difficulty.name,
        'durationMinutes': durationMinutes,
        'date': date.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'startTime': startTime,
        'spentSeconds': spentSeconds,
        'startedAt': startedAt?.toIso8601String(),
        'statement': statement,
        'examples': examples.map((e) => e.toJson()).toList(),
        'hint': hint,
        'solution': solution,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        difficulty: TaskDifficulty.values.firstWhere(
          (e) => e.name == json['difficulty'],
          orElse: () => TaskDifficulty.easy,
        ),
        durationMinutes: json['durationMinutes'] as int? ?? 30,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        deadline:
            DateTime.tryParse(json['deadline'] as String? ?? '') ?? DateTime.now(),
        status: TaskStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => TaskStatus.pending,
        ),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        startTime: json['startTime'] as String?,
        spentSeconds: json['spentSeconds'] as int? ?? 0,
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
        statement: json['statement'] as String? ?? '',
        examples: (json['examples'] as List?)
                ?.whereType<Map>()
                .map((e) => TaskExample.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        hint: json['hint'] as String? ?? '',
        solution: json['solution'] as String? ?? '',
      );
}
