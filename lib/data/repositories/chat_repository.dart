import '../models/chat_message.dart';
import '../remote/firestore_service.dart';

class ChatRepository {
  const ChatRepository();

  static const _name = 'chat';

  Future<List<ChatMessage>> all(String userId) async {
    final items = await FirestoreService.readAll(userId, _name);
    final messages = items.map(ChatMessage.fromJson).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return messages;
  }

  Future<void> saveAll(String userId, List<ChatMessage> messages) =>
      FirestoreService.replaceAll(
        userId,
        _name,
        messages.map((e) => e.toJson()).toList(),
      );
}
