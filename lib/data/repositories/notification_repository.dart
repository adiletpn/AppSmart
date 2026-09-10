import '../models/app_notification.dart';
import '../remote/firestore_service.dart';

class NotificationRepository {
  const NotificationRepository();

  static const _name = 'notifications';

  Future<List<AppNotification>> all(String userId) async {
    final items = await FirestoreService.readAll(userId, _name);
    final list = items.map(AppNotification.fromJson).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  Future<void> saveAll(String userId, List<AppNotification> items) =>
      FirestoreService.replaceAll(
        userId,
        _name,
        items.map((e) => e.toJson()).toList(),
      );
}
