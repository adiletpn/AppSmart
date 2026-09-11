import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/l10n.dart';
import '../core/time_utils.dart';
import '../data/ai/free_time_engine.dart';
import '../data/ai/local_mentor_ai.dart';
import '../data/ai/mentor_ai.dart';
import '../data/models/app_notification.dart';
import '../data/models/app_user.dart';
import '../data/models/chat_message.dart';
import '../data/models/day_summary.dart';
import '../data/models/progress_stats.dart';
import '../data/models/schedule_item.dart';
import '../data/models/study_task.dart';
import '../data/models/test_result.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/remote/firestore_service.dart';
import '../services/fcm_service.dart';
import '../services/push_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.auth,
    required this.tasksRepo,
    required this.scheduleRepo,
    required this.progressRepo,
    required this.chatRepo,
    required this.notificationsRepo,
  });

  final AuthRepository auth;
  final TaskRepository tasksRepo;
  final ScheduleRepository scheduleRepo;
  final ProgressRepository progressRepo;
  final ChatRepository chatRepo;
  final NotificationRepository notificationsRepo;

  static const _uuid = Uuid();

  MentorAi _ai = const LocalMentorAi();
  AppUser? _user;
  List<StudyTask> _tasks = [];
  List<ScheduleItem> _schedule = [];
  List<TestResult> _tests = [];
  List<ChatMessage> _messages = [];
  List<AppNotification> _notifications = [];
  bool _busy = false;
  bool _thinking = false;
  bool _isKz = true;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  bool get thinking => _thinking;
  List<StudyTask> get tasks => List.unmodifiable(_tasks);
  List<ScheduleItem> get schedule => List.unmodifiable(_schedule);
  List<TestResult> get tests => List.unmodifiable(_tests);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void configure({required MentorAi ai, required bool isKz}) {
    final languageChanged = _isKz != isKz;
    _ai = ai;
    _isKz = isKz;
    if (!languageChanged) return;
    final user = _user;
    if (user == null || !user.profileCompleted) return;
    scheduleMicrotask(() async {
      await generatePlan(DateTime.now(), force: true);
      await refreshAdvice();
    });
  }

  L10n get _l => L10n(_isKz ? AppLang.kk : AppLang.ru);

  Future<void> bootstrap() async {
    _user = await auth.currentUser();
    if (_user != null) await _loadUserData();
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final id = _user!.id;
    _tasks = await tasksRepo.all(id);
    _schedule = await scheduleRepo.all(id);
    _tests = await progressRepo.all(id);
    _messages = await chatRepo.all(id);
    _notifications = await notificationsRepo.all(id);
    _syncMissedTasks();
    unawaited(_registerPushToken(id));
  }

  Future<void> _registerPushToken(String userId) async {
    final token = await FcmService.setup();
    if (token == null) return;
    await FirestoreService.user(userId).set(
      {'fcmToken': token, 'fcmUpdatedAt': DateTime.now().toIso8601String()},
      SetOptions(merge: true),
    );
  }

  void _syncMissedTasks() {
    final today = TimeUtils.dayStart(DateTime.now());
    var changed = false;
    _tasks = _tasks.map((task) {
      if (task.status == TaskStatus.done) return task;
      if (task.date.isBefore(today) && task.status != TaskStatus.missed) {
        changed = true;
        return task.copyWith(status: TaskStatus.missed);
      }
      return task;
    }).toList();
    if (changed) _persistTasks();
  }

  Future<void> register(String name, String email, String password) async {
    _setBusy(true);
    try {
      _user = await auth.register(name: name, email: email, password: password);
      await _loadUserData();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setBusy(true);
    try {
      _user = await auth.login(email: email, password: password);
      await _loadUserData();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resetPassword(String email) => auth.sendPasswordReset(email);

  Future<void> logout() async {
    await auth.logout();
    _user = null;
    _tasks = [];
    _schedule = [];
    _tests = [];
    _messages = [];
    _notifications = [];
    notifyListeners();
  }

  Future<void> saveProfile(AppUser updated) async {
    _user = await auth.save(updated);
    notifyListeners();
  }

  Future<void> completeProfile(AppUser updated) async {
    await saveProfile(updated.copyWith(profileCompleted: true));
    await generatePlan(DateTime.now(), force: true);
  }

  List<StudyTask> tasksFor(DateTime date) =>
      _tasks.where((t) => TimeUtils.sameDay(t.date, date)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<ScheduleItem> scheduleFor(DateTime date) =>
      _schedule.where((s) => TimeUtils.sameDay(s.date, date)).toList()
        ..sort((a, b) => TimeUtils.toMinutes(a.startTime)
            .compareTo(TimeUtils.toMinutes(b.startTime)));

  List<StudyTask> get todayTasks => tasksFor(DateTime.now());

  int freeMinutesFor(DateTime date) =>
      _user == null ? 0 : FreeTimeEngine.freeMinutes(_user!, date, _l);

  List<DaySummary> weekOverview(DateTime anchor) {
    final monday = TimeUtils.dayStart(
      anchor.subtract(Duration(days: anchor.weekday - 1)),
    );
    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      final tasks = tasksFor(day);
      return DaySummary(
        date: day,
        freeMinutes: freeMinutesFor(day),
        studyMinutes:
            tasks.fold<int>(0, (total, task) => total + task.durationMinutes),
        totalTasks: tasks.length,
        doneTasks: tasks.where((task) => task.isDone).length,
      );
    });
  }

  String _advice = '';
  String get advice => _advice;

  PlanSource? _lastPlanSource;
  PlanSource? get lastPlanSource => _lastPlanSource;

  bool get aiFellBack =>
      _aiRequested && _lastPlanSource == PlanSource.local;

  bool _aiRequested = false;

  void dismissFallbackNotice() {
    _aiRequested = false;
    notifyListeners();
  }

  Future<void> generatePlan(DateTime date, {bool force = false}) async {
    final user = _user;
    if (user == null) return;
    if (!force && tasksFor(date).isNotEmpty) return;

    _setBusy(true);
    _aiRequested = _ai is! LocalMentorAi;
    try {
      final plan = await _ai.buildDay(
        user: user,
        date: date,
        stats: stats,
        history: _tasks,
        isKz: _isKz,
      );
      _tasks.removeWhere(
          (t) => TimeUtils.sameDay(t.date, date) && t.status != TaskStatus.done);
      _schedule.removeWhere((s) => TimeUtils.sameDay(s.date, date) && !s.manual);
      _tasks.addAll(plan.tasks);
      _schedule.addAll(plan.schedule);
      _advice = plan.advice;
      _lastPlanSource = plan.source;
      await _persistTasks();
      await _persistSchedule();
      if (plan.tasks.isNotEmpty) {
        await pushNotification(
          type: NotificationType.tasksReady,
          title: _l.t('Бүгінгі тапсырмалар дайын',
              'Задания на сегодня готовы'),
          body: _l.t(
            '${plan.tasks.length} тапсырма, барлығы ${_l.duration(plan.studyMinutes)}.',
            '${plan.tasks.length} задания, всего ${_l.duration(plan.studyMinutes)}.',
          ),
        );
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> refreshAdvice() async {
    final user = _user;
    if (user == null) return;
    _advice = await _ai.advice(
      user: user,
      stats: stats,
      today: todayTasks,
      isKz: _isKz,
    );
    notifyListeners();
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks[index];
    final stopTimer = task.isRunning && status != TaskStatus.inProgress;
    _tasks[index] = task.copyWith(
      status: status,
      completedAt: status == TaskStatus.done ? DateTime.now() : null,
      clearCompletedAt: status != TaskStatus.done,
      spentSeconds: stopTimer ? task.elapsedSeconds : null,
      clearStartedAt: stopTimer,
    );
    await _persistTasks();
    if (status == TaskStatus.done) await _celebrate();
  }

  Future<void> startTimer(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1 || _tasks[index].isRunning) return;
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].isRunning) {
        _tasks[i] = _tasks[i].copyWith(
          spentSeconds: _tasks[i].elapsedSeconds,
          clearStartedAt: true,
        );
      }
    }
    _tasks[index] = _tasks[index].copyWith(
      status: TaskStatus.inProgress,
      startedAt: DateTime.now(),
    );
    await _persistTasks();
  }

  Future<void> pauseTimer(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1 || !_tasks[index].isRunning) return;
    _tasks[index] = _tasks[index].copyWith(
      spentSeconds: _tasks[index].elapsedSeconds,
      clearStartedAt: true,
    );
    await _persistTasks();
  }

  Future<void> _celebrate() async {
    final current = stats;
    final left = todayTasks.where((t) => !t.isDone).length;
    if (left == 0 && todayTasks.isNotEmpty) {
      await pushNotification(
        type: NotificationType.streak,
        title: _l.t('Күндік жоспар орындалды', 'Дневной план выполнен'),
        body: _l.t(
          'Барлық тапсырма аяқталды. Серия: ${current.streakDays} күн.',
          'Все задания закрыты. Серия: ${current.streakDays} дн.',
        ),
      );
    }
    await refreshAdvice();
  }

  Future<void> addTask(StudyTask task) async {
    _tasks.add(task);
    await _persistTasks();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    _schedule.removeWhere((s) => s.taskId == taskId);
    await _persistTasks();
    await _persistSchedule();
  }

  Future<void> upsertScheduleItem(ScheduleItem item) async {
    final index = _schedule.indexWhere((s) => s.id == item.id);
    if (index == -1) {
      _schedule.add(item);
    } else {
      _schedule[index] = item;
    }
    await _persistSchedule();
  }

  Future<void> deleteScheduleItem(String id) async {
    _schedule.removeWhere((s) => s.id == id);
    await _persistSchedule();
  }

  Future<void> addTestResult(String topic, int score, int total) async {
    final user = _user;
    if (user == null) return;
    _tests.add(TestResult(
      id: _uuid.v4(),
      userId: user.id,
      topic: topic,
      score: score,
      total: total,
      date: DateTime.now(),
    ));
    await progressRepo.saveAll(user.id, _tests);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final user = _user;
    if (user == null || text.trim().isEmpty) return;
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      userId: user.id,
      role: ChatRole.user,
      text: text.trim(),
      time: DateTime.now(),
    ));
    _thinking = true;
    notifyListeners();
    await chatRepo.saveAll(user.id, _messages);

    final answer = await _ai.reply(
      user: user,
      stats: stats,
      today: todayTasks,
      history: _messages,
      message: text.trim(),
      isKz: _isKz,
    );
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      userId: user.id,
      role: ChatRole.mentor,
      text: answer,
      time: DateTime.now(),
    ));
    _thinking = false;
    notifyListeners();
    await chatRepo.saveAll(user.id, _messages);
  }

  Future<void> clearChat() async {
    final user = _user;
    if (user == null) return;
    _messages = [];
    await chatRepo.saveAll(user.id, _messages);
    notifyListeners();
  }

  Future<void> pushNotification({
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    final user = _user;
    if (user == null) return;
    _notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        userId: user.id,
        type: type,
        title: title,
        body: body,
        time: DateTime.now(),
      ),
    );
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }
    await notificationsRepo.saveAll(user.id, _notifications);
    notifyListeners();
  }

  Future<void> scheduleDeviceNotifications({
    required bool reminders,
    required bool deadlines,
  }) async {
    final user = _user;
    if (user == null || !PushService.supported) return;
    await PushService.cancelAll();

    final day = TimeUtils.dayStart(DateTime.now());
    if (reminders) {
      for (final slot in scheduleFor(day).where((s) => s.type == SlotType.study)) {
        final minutes = TimeUtils.toMinutes(slot.startTime) - 10;
        if (minutes < 0) continue;
        await PushService.schedule(
          key: slot.id,
          title: _l.t('Дайындық басталады', 'Скоро занятие'),
          body: _l.t(
            '${slot.startTime}-де «${slot.title}». Дайындал!',
            'В ${slot.startTime} — «${slot.title}». Готовься!',
          ),
          when: day.add(Duration(minutes: minutes)),
        );
      }
    }

    if (deadlines && tasksFor(day).any((t) => !t.isDone)) {
      await PushService.schedule(
        key: 'deadline_${TimeUtils.dateKey(day)}',
        title: _l.t('Дедлайн жақындады', 'Дедлайн близко'),
        body: _l.t(
          'Бүгінгі тапсырмаларды жабуға уақыт аз қалды.',
          'Осталось немного времени, чтобы закрыть задания.',
        ),
        when: day.add(const Duration(hours: 20)),
      );
    }
  }

  bool _hasNotificationToday(NotificationType type) {
    final today = TimeUtils.dayStart(DateTime.now());
    return _notifications.any(
      (n) => n.type == type && !n.time.isBefore(today),
    );
  }

  Future<void> syncReminders({
    required bool reminders,
    required bool deadlines,
    required bool weekly,
  }) async {
    final user = _user;
    if (user == null) return;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final today = todayTasks;
    final pending = today.where((t) => !t.isDone).toList();

    if (reminders && !_hasNotificationToday(NotificationType.reminder)) {
      final next = scheduleFor(now)
          .where((s) =>
              s.type == SlotType.study &&
              TimeUtils.toMinutes(s.startTime) - nowMinutes > 0 &&
              TimeUtils.toMinutes(s.startTime) - nowMinutes <= 60)
          .firstOrNull;
      if (next != null) {
        final left = TimeUtils.toMinutes(next.startTime) - nowMinutes;
        await pushNotification(
          type: NotificationType.reminder,
          title: _l.t('Дайындық жақындады', 'Скоро занятие'),
          body: _l.t(
            '${next.startTime}-де «${next.title}» басталады. $left минут қалды.',
            'В ${next.startTime} начинается «${next.title}». Осталось $left мин.',
          ),
        );
      }
    }

    if (deadlines &&
        pending.isNotEmpty &&
        nowMinutes >= 20 * 60 &&
        !_hasNotificationToday(NotificationType.deadline)) {
      await pushNotification(
        type: NotificationType.deadline,
        title: _l.t('Дедлайн жақын', 'Дедлайн близко'),
        body: _l.t(
          'Бүгін ${pending.length} тапсырма орындалмай тұр. Кеш бітпей үлгер.',
          'Сегодня не закрыто заданий: ${pending.length}. Успей до конца дня.',
        ),
      );
    }

    if (weekly &&
        now.weekday == DateTime.sunday &&
        nowMinutes >= 18 * 60 &&
        !_hasNotificationToday(NotificationType.weekly)) {
      final current = stats;
      final weekTotal =
          current.weeklyCompleted.fold<int>(0, (total, value) => total + value);
      await pushNotification(
        type: NotificationType.weekly,
        title: _l.t('Апталық нәтиже', 'Итоги недели'),
        body: _l.t(
          'Осы аптада $weekTotal тапсырма орындалды. Серия: ${current.streakDays} күн.',
          'За неделю выполнено заданий: $weekTotal. Серия: ${current.streakDays} дн.',
        ),
      );
    }
  }

  Future<void> markNotificationsRead() async {
    final user = _user;
    if (user == null) return;
    _notifications =
        _notifications.map((n) => n.copyWith(read: true)).toList();
    await notificationsRepo.saveAll(user.id, _notifications);
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    final user = _user;
    if (user == null) return;
    _notifications = [];
    await notificationsRepo.saveAll(user.id, _notifications);
    notifyListeners();
  }

  ProgressStats get stats {
    final done = _tasks.where((t) => t.isDone).toList();
    final studyMinutes =
        done.fold<int>(0, (total, t) => total + t.durationMinutes);
    final trackedMinutes =
        _tasks.fold<int>(0, (total, t) => total + t.spentMinutes);
    final days = done.map((t) => TimeUtils.dateKey(t.date)).toSet();

    var streak = 0;
    var cursor = TimeUtils.dayStart(DateTime.now());
    if (!days.contains(TimeUtils.dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(TimeUtils.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final testAverage = _tests.isEmpty
        ? 0.0
        : _tests.map((t) => t.percent).reduce((a, b) => a + b) / _tests.length;

    final scores = <String, List<double>>{};
    for (final task in _tasks) {
      if (task.topic.isEmpty) continue;
      scores.putIfAbsent(task.topic, () => []).add(task.isDone ? 1 : 0);
    }
    for (final test in _tests) {
      scores.putIfAbsent(test.topic, () => []).add(test.percent);
    }
    final topicScores = scores.map((key, value) =>
        MapEntry(key, value.reduce((a, b) => a + b) / value.length));

    final weekStart = TimeUtils.dayStart(DateTime.now())
        .subtract(Duration(days: DateTime.now().weekday - 1));
    final weekly = List<int>.filled(7, 0);
    for (final task in done) {
      final diff = TimeUtils.dayStart(task.date).difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) weekly[diff]++;
    }

    return ProgressStats(
      completedTasks: done.length,
      totalTasks: _tasks.length,
      studyMinutes: studyMinutes,
      trackedMinutes: trackedMinutes,
      streakDays: streak,
      activeDays: days.length,
      testAverage: testAverage,
      topicScores: topicScores,
      weeklyCompleted: weekly,
    );
  }

  Future<void> _persistTasks() async {
    final user = _user;
    if (user == null) return;
    await tasksRepo.saveAll(user.id, _tasks);
    notifyListeners();
  }

  Future<void> _persistSchedule() async {
    final user = _user;
    if (user == null) return;
    await scheduleRepo.saveAll(user.id, _schedule);
    notifyListeners();
  }

  Future<void> wipeData() async {
    final user = _user;
    if (user == null) return;
    for (final name in ['tasks', 'schedule', 'tests', 'chat', 'notifications']) {
      await FirestoreService.deleteAll(user.id, name);
    }
    _tasks = [];
    _schedule = [];
    _tests = [];
    _messages = [];
    _notifications = [];
    notifyListeners();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
