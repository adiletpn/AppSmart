enum NotificationType { reminder, tasksReady, deadline, streak, weekly }

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        time: time,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'time': time.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['userId'] as String,
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.reminder,
        ),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        read: json['read'] as bool? ?? false,
      );
}
