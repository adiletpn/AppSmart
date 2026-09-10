import '../models/test_result.dart';
import '../remote/firestore_service.dart';

class ProgressRepository {
  const ProgressRepository();

  static const _name = 'tests';

  Future<List<TestResult>> all(String userId) async {
    final items = await FirestoreService.readAll(userId, _name);
    return items.map(TestResult.fromJson).toList();
  }

  Future<void> saveAll(String userId, List<TestResult> results) =>
      FirestoreService.replaceAll(
        userId,
        _name,
        results.map((e) => e.toJson()).toList(),
      );
}
