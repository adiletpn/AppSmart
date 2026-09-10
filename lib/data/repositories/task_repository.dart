import '../models/study_task.dart';
import '../remote/firestore_service.dart';

class TaskRepository {
  const TaskRepository();

  static const _name = 'tasks';

  Future<List<StudyTask>> all(String userId) async {
    final items = await FirestoreService.readAll(userId, _name);
    return items.map(StudyTask.fromJson).toList();
  }

  Future<void> saveAll(String userId, List<StudyTask> tasks) =>
      FirestoreService.replaceAll(
        userId,
        _name,
        tasks.map((e) => e.toJson()).toList(),
      );
}
