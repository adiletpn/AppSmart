enum SlotType { school, sleep, meal, extra, study, free }

class ScheduleItem {
  final String id;
  final String userId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final SlotType type;
  final String title;
  final String? taskId;
  final bool manual;

  const ScheduleItem({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.title,
    this.taskId,
    this.manual = false,
  });

  ScheduleItem copyWith({
    String? startTime,
    String? endTime,
    SlotType? type,
    String? title,
    String? taskId,
    bool? manual,
  }) =>
      ScheduleItem(
        id: id,
        userId: userId,
        date: date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        type: type ?? this.type,
        title: title ?? this.title,
        taskId: taskId ?? this.taskId,
        manual: manual ?? this.manual,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'type': type.name,
        'title': title,
        'taskId': taskId,
        'manual': manual,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] as String,
        userId: json['userId'] as String,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        startTime: json['startTime'] as String? ?? '00:00',
        endTime: json['endTime'] as String? ?? '00:00',
        type: SlotType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SlotType.free,
        ),
        title: json['title'] as String? ?? '',
        taskId: json['taskId'] as String?,
        manual: json['manual'] as bool? ?? false,
      );
}
