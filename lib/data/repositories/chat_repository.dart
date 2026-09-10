import '../local/local_store.dart';
import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository(this._store);

  final LocalStore _store;

  String _key(String userId) => 'chat_$userId';

  List<ChatMessage> all(String userId) =>
      _store.readList(_key(userId)).map(ChatMessage.fromJson).toList();

  Future<void> saveAll(String userId, List<ChatMessage> messages) =>
      _store.writeList(_key(userId), messages.map((e) => e.toJson()).toList());
}
