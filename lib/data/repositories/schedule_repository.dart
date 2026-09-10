import '../local/local_store.dart';
import '../models/schedule_item.dart';

class ScheduleRepository {
  ScheduleRepository(this._store);

  final LocalStore _store;

  String _key(String userId) => 'schedule_$userId';

  List<ScheduleItem> all(String userId) =>
      _store.readList(_key(userId)).map(ScheduleItem.fromJson).toList();

  Future<void> saveAll(String userId, List<ScheduleItem> items) =>
      _store.writeList(_key(userId), items.map((e) => e.toJson()).toList());
}
