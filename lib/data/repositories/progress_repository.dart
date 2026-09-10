import '../local/local_store.dart';
import '../models/test_result.dart';

class ProgressRepository {
  ProgressRepository(this._store);

  final LocalStore _store;

  String _key(String userId) => 'tests_$userId';

  List<TestResult> all(String userId) =>
      _store.readList(_key(userId)).map(TestResult.fromJson).toList();

  Future<void> saveAll(String userId, List<TestResult> results) =>
      _store.writeList(_key(userId), results.map((e) => e.toJson()).toList());
}
