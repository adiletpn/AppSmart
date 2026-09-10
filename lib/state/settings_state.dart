import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../data/local/local_store.dart';

class SettingsState extends ChangeNotifier {
  SettingsState(this._store) {
    _load();
  }

  final LocalStore _store;

  AppLang _lang = AppLang.kk;
  ThemeMode _themeMode = ThemeMode.system;
  bool _remindersEnabled = true;
  bool _deadlineAlerts = true;
  bool _weeklyReport = true;
  bool _onboardingSeen = false;
  String _apiKey = '';

  AppLang get lang => _lang;
  ThemeMode get themeMode => _themeMode;
  bool get remindersEnabled => _remindersEnabled;
  bool get deadlineAlerts => _deadlineAlerts;
  bool get weeklyReport => _weeklyReport;
  bool get onboardingSeen => _onboardingSeen;
  String get apiKey => _apiKey;
  bool get aiConnected => _apiKey.trim().isNotEmpty;
  L10n get l => L10n(_lang);

  void _load() {
    final data = _store.readMap('settings') ?? {};
    _lang = AppLang.values.firstWhere(
      (e) => e.name == data['lang'],
      orElse: () => AppLang.kk,
    );
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == data['themeMode'],
      orElse: () => ThemeMode.system,
    );
    _remindersEnabled = data['remindersEnabled'] as bool? ?? true;
    _deadlineAlerts = data['deadlineAlerts'] as bool? ?? true;
    _weeklyReport = data['weeklyReport'] as bool? ?? true;
    _onboardingSeen = data['onboardingSeen'] as bool? ?? false;
    _apiKey = data['apiKey'] as String? ?? '';
  }

  Future<void> _persist() => _store.writeMap('settings', {
        'lang': _lang.name,
        'themeMode': _themeMode.name,
        'remindersEnabled': _remindersEnabled,
        'deadlineAlerts': _deadlineAlerts,
        'weeklyReport': _weeklyReport,
        'onboardingSeen': _onboardingSeen,
        'apiKey': _apiKey,
      });

  Future<void> setLang(AppLang value) async {
    _lang = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setReminders(bool value) async {
    _remindersEnabled = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setDeadlineAlerts(bool value) async {
    _deadlineAlerts = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setWeeklyReport(bool value) async {
    _weeklyReport = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setOnboardingSeen() async {
    _onboardingSeen = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setApiKey(String value) async {
    _apiKey = value.trim();
    notifyListeners();
    await _persist();
  }
}
