import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../local/local_store.dart';
import '../models/app_user.dart';

class AuthException implements Exception {
  AuthException(this.messageKz, this.messageRu);
  final String messageKz;
  final String messageRu;
}

class AuthRepository {
  AuthRepository(this._store);

  final LocalStore _store;
  static const _usersKey = 'users';
  static const _credsKey = 'credentials';
  static const _sessionKey = 'session_user_id';
  static const _uuid = Uuid();

  String _hash(String password) =>
      base64Encode(utf8.encode('smart_mentor::$password'));

  List<AppUser> _users() =>
      _store.readList(_usersKey).map(AppUser.fromJson).toList();

  Future<void> _saveUsers(List<AppUser> users) =>
      _store.writeList(_usersKey, users.map((e) => e.toJson()).toList());

  Map<String, dynamic> _credentials() => _store.readMap(_credsKey) ?? {};

  AppUser? currentUser() {
    final id = _store.readString(_sessionKey);
    if (id == null) return null;
    for (final user in _users()) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final users = _users();
    if (users.any((u) => u.email.toLowerCase() == normalized)) {
      throw AuthException(
        'Бұл email тіркелген',
        'Этот email уже зарегистрирован',
      );
    }
    final user = AppUser(
      id: _uuid.v4(),
      name: name.trim(),
      email: normalized,
      createdAt: DateTime.now(),
    );
    users.add(user);
    await _saveUsers(users);
    final creds = _credentials()..[normalized] = _hash(password);
    await _store.writeMap(_credsKey, creds);
    await _store.writeString(_sessionKey, user.id);
    return user;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final creds = _credentials();
    if (creds[normalized] != _hash(password)) {
      throw AuthException(
        'Email немесе құпиясөз қате',
        'Неверный email или пароль',
      );
    }
    final user = _users().firstWhere((u) => u.email.toLowerCase() == normalized);
    await _store.writeString(_sessionKey, user.id);
    return user;
  }

  Future<void> resetPassword({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final creds = _credentials();
    if (!creds.containsKey(normalized)) {
      throw AuthException('Мұндай email табылмады', 'Такой email не найден');
    }
    creds[normalized] = _hash(password);
    await _store.writeMap(_credsKey, creds);
  }

  Future<void> logout() => _store.remove(_sessionKey);

  Future<AppUser> save(AppUser user) async {
    final users = _users();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      users.add(user);
    } else {
      users[index] = user;
    }
    await _saveUsers(users);
    return user;
  }
}
