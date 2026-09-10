import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> users() =>
      db.collection('users');

  static DocumentReference<Map<String, dynamic>> user(String userId) =>
      users().doc(userId);

  static CollectionReference<Map<String, dynamic>> collection(
    String userId,
    String name,
  ) =>
      user(userId).collection(name);

  static Future<List<Map<String, dynamic>>> readAll(
    String userId,
    String name,
  ) async {
    final snapshot = await collection(userId, name).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Future<void> replaceAll(
    String userId,
    String name,
    List<Map<String, dynamic>> items,
  ) async {
    final ref = collection(userId, name);
    final existing = await ref.get();
    final ids = items.map((item) => item['id'] as String).toSet();
    final batch = db.batch();

    for (final doc in existing.docs) {
      if (!ids.contains(doc.id)) batch.delete(doc.reference);
    }
    for (final item in items) {
      batch.set(ref.doc(item['id'] as String), item);
    }
    await batch.commit();
  }

  static Future<void> deleteAll(String userId, String name) async {
    final snapshot = await collection(userId, name).get();
    final batch = db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
