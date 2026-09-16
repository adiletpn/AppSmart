import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/schedule_item.dart';
import '../models/study_task.dart';
import '../models/test_result.dart';
import 'local_store.dart';

class CachedData {
  final List<StudyTask> tasks;
  final List<ScheduleItem> schedule;
  final List<TestResult> tests;
  final List<ChatMessage> messages;
  final List<AppNotification> notifications;

  const CachedData({
    this.tasks = const [],
    this.schedule = const [],
    this.tests = const [],
    this.messages = const [],
    this.notifications = const [],
  });

  bool get isEmpty =>
      tasks.isEmpty &&
      schedule.isEmpty &&
      tests.isEmpty &&
      messages.isEmpty &&
      notifications.isEmpty;
}

/// Оқушының деректерін құрылғыда сақтайды: интернет жоқта да, баяу байланыста
/// да қосымша бірден толық көрініспен ашылуы керек.
class LocalCache {
  const LocalCache(this._store);

  final LocalStore _store;

  static String _key(String name, String userId) => 'cache_${name}_$userId';

  AppUser? readUser(String userId) {
    try {
      final data = _store.readMap(_key('user', userId));
      return data == null ? null : AppUser.fromJson(data);
    } on Exception {
      return null;
    }
  }

  Future<void> writeUser(AppUser user) =>
      _store.writeMap(_key('user', user.id), user.toJson());

  CachedData read(String userId) {
    try {
      return CachedData(
        tasks: _read(_key('tasks', userId), StudyTask.fromJson),
        schedule: _read(_key('schedule', userId), ScheduleItem.fromJson),
        tests: _read(_key('tests', userId), TestResult.fromJson),
        messages: _read(_key('chat', userId), ChatMessage.fromJson),
        notifications:
            _read(_key('notifications', userId), AppNotification.fromJson),
      );
    } on Exception {
      // Ескі не бүлінген көшірме бүкіл қосымшаны құлатпауы тиіс.
      return const CachedData();
    }
  }

  Future<void> write(String userId, CachedData data) async {
    await _write(_key('tasks', userId), data.tasks.map((e) => e.toJson()));
    await _write(
        _key('schedule', userId), data.schedule.map((e) => e.toJson()));
    await _write(_key('tests', userId), data.tests.map((e) => e.toJson()));
    await _write(_key('chat', userId), data.messages.map((e) => e.toJson()));
    await _write(_key('notifications', userId),
        data.notifications.map((e) => e.toJson()));
  }

  Future<void> clear(String userId) => _store.clearUserData(userId);

  List<T> _read<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      _store.readList(key).map(fromJson).toList();

  Future<void> _write(String key, Iterable<Map<String, dynamic>> items) =>
      _store.writeList(key, items.toList());
}
