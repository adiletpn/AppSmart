import '../local/local_store.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._store);

  final LocalStore _store;

  String _key(String userId) => 'notifications_$userId';

  List<AppNotification> all(String userId) =>
      _store.readList(_key(userId)).map(AppNotification.fromJson).toList();

  Future<void> saveAll(String userId, List<AppNotification> items) =>
      _store.writeList(_key(userId), items.map((e) => e.toJson()).toList());
}
