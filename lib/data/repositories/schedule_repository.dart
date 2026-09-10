import '../models/schedule_item.dart';
import '../remote/firestore_service.dart';

class ScheduleRepository {
  const ScheduleRepository();

  static const _name = 'schedule';

  Future<List<ScheduleItem>> all(String userId) async {
    final items = await FirestoreService.readAll(userId, _name);
    return items.map(ScheduleItem.fromJson).toList();
  }

  Future<void> saveAll(String userId, List<ScheduleItem> items) =>
      FirestoreService.replaceAll(
        userId,
        _name,
        items.map((e) => e.toJson()).toList(),
      );
}
