import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../remote/firestore_service.dart';

class AuthException implements Exception {
  AuthException(this.messageKz, this.messageRu);
  final String messageKz;
  final String messageRu;
}

class AuthRepository {
  const AuthRepository();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<AppUser?> currentUser() async {
    final account = _auth.currentUser;
    if (account == null) return null;
    return _profileOf(account);
  }

  Future<AppUser> _profileOf(User account) async {
    final snapshot = await FirestoreService.user(account.uid).get();
    final data = snapshot.data();
    if (data != null) return AppUser.fromJson(data);

    final created = AppUser(
      id: account.uid,
      name: account.displayName ?? '',
      email: account.email ?? '',
      createdAt: DateTime.now(),
    );
    await FirestoreService.user(created.id).set(created.toJson());
    return created;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final account = credential.user!;
      await account.updateDisplayName(name.trim());
      final user = AppUser(
        id: account.uid,
        name: name.trim(),
        email: account.email ?? email.trim().toLowerCase(),
        createdAt: DateTime.now(),
      );
      await FirestoreService.user(user.id).set(user.toJson());
      return user;
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return _profileOf(credential.user!);
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser> save(AppUser user) async {
    await FirestoreService.user(user.id).set(user.toJson());
    return user;
  }

  AuthException _mapError(FirebaseAuthException error) => switch (error.code) {
        'email-already-in-use' => AuthException(
            'Бұл email тіркелген',
            'Этот email уже зарегистрирован',
          ),
        'invalid-email' => AuthException(
            'Email форматы қате',
            'Неверный формат email',
          ),
        'weak-password' => AuthException(
            'Құпиясөз тым қарапайым',
            'Слишком простой пароль',
          ),
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          AuthException(
            'Email немесе құпиясөз қате',
            'Неверный email или пароль',
          ),
        'user-disabled' => AuthException(
            'Бұл аккаунт бұғатталған',
            'Этот аккаунт заблокирован',
          ),
        'too-many-requests' => AuthException(
            'Тым көп әрекет. Сәл кейінірек көр',
            'Слишком много попыток. Попробуй позже',
          ),
        'network-request-failed' => AuthException(
            'Интернет байланысы жоқ',
            'Нет соединения с интернетом',
          ),
        _ => AuthException(
            'Қате: ${error.code}',
            'Ошибка: ${error.code}',
          ),
      };
}
