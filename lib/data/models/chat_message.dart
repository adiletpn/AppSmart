enum ChatRole { user, mentor }

class ChatMessage {
  final String id;
  final String userId;
  final ChatRole role;
  final String text;
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'role': role.name,
        'text': text,
        'time': time.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        userId: json['userId'] as String,
        role: ChatRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => ChatRole.mentor,
        ),
        text: json['text'] as String? ?? '',
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}
