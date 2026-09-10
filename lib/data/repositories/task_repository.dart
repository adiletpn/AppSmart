import '../local/local_store.dart';
import '../models/study_task.dart';

class TaskRepository {
  TaskRepository(this._store);

  final LocalStore _store;

  String _key(String userId) => 'tasks_$userId';

  List<StudyTask> all(String userId) =>
      _store.readList(_key(userId)).map(StudyTask.fromJson).toList();

  Future<void> saveAll(String userId, List<StudyTask> tasks) =>
      _store.writeList(_key(userId), tasks.map((e) => e.toJson()).toList());
}
