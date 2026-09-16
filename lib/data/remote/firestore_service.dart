import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Соңғы жазу серверге жеткен-жетпегенін білдіреді.
  static bool get hasPendingWrites => _pending > 0;

  static int _pending = 0;

  static final _pendingChanges = StreamController<bool>.broadcast();

  static Stream<bool> get pendingChanges => _pendingChanges.stream;

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
    final batch = db.batch();

    // Бар жазбаларды оқу сәтсіз болса да, жаңа деректі жазып қалу керек:
    // әйтпесе оқушының офлайнда істеген жұмысы кезекке де түспей жоғалады.
    try {
      final existing = await ref.get();
      final ids = items.map((item) => item['id'] as String).toSet();
      for (final doc in existing.docs) {
        if (!ids.contains(doc.id)) batch.delete(doc.reference);
      }
    } on Exception {
      // Артық жазбаларды тазалау келесі сәтті сақтауға қалдырылады.
    }

    for (final item in items) {
      batch.set(ref.doc(item['id'] as String), item);
    }
    _commit(batch);
  }

  static Future<void> deleteAll(String userId, String name) async {
    try {
      final snapshot = await collection(userId, name).get();
      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      _commit(batch);
    } on Exception {
      // Байланыс жоқта тазалау мүмкін емес — келесі әрекетте қайталанады.
    }
  }

  /// Firestore жазуды жергілікті кэшке бірден қолданады, ал commit() тек
  /// сервер жауап бергенде аяқталады. Байланыс жоқта оны күтсек, қосымша
  /// қатып қалады — сондықтан күтпейміз, тек жеткенін белгілеп отырамыз.
  static void _commit(WriteBatch batch) {
    _pending++;
    _pendingChanges.add(true);
    batch.commit().whenComplete(() {
      _pending--;
      _pendingChanges.add(hasPendingWrites);
    }).ignore();
  }
}
