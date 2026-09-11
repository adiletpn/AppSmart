import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/progress_stats.dart';
import '../models/schedule_item.dart';
import '../models/study_task.dart';
import 'free_time_engine.dart';
import 'mentor_ai.dart';
import 'pace_analyzer.dart';
import 'topic_catalog.dart';

class LocalMentorAi implements MentorAi {
  const LocalMentorAi();

  static const _uuid = Uuid();

  @override
  Future<DailyPlan> buildDay({
    required AppUser user,
    required DateTime date,
    required ProgressStats stats,
    required List<StudyTask> history,
    required bool isKz,
  }) async {
    final l = L10n(isKz ? AppLang.kk : AppLang.ru);
    final windows = FreeTimeEngine.freeWindows(user, date, l);
    final freeMinutes = windows.fold<int>(0, (sum, w) => sum + w.minutes);
    final pace = PaceAnalyzer.analyze(history, date);
    final budget = pace.adjustBudget(
      min(freeMinutes, user.dailyStudyMinutes),
    );

    final topics = _pickTopics(user, stats, history, date);
    final difficulty = _difficultyFor(user, stats, history, pace);
    final tasks = _buildTasks(
      user: user,
      date: date,
      budget: budget,
      topics: topics,
      base: difficulty,
      isKz: isKz,
    );

    final schedule = buildSchedule(
      user: user,
      date: date,
      tasks: tasks,
      l: l,
    );

    return DailyPlan(
      tasks: tasks,
      schedule: schedule,
      advice: await advice(
        user: user,
        stats: stats,
        today: tasks,
        isKz: isKz,
      ),
      freeMinutes: freeMinutes,
      studyMinutes: tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes),
    );
  }

  List<Topic> _pickTopics(
    AppUser user,
    ProgressStats stats,
    List<StudyTask> history,
    DateTime date,
  ) {
    final pool = TopicCatalog.forLevel(user.level);
    final weak = stats.weakTopics
        .map((e) => TopicCatalog.byName(e.key))
        .whereType<Topic>()
        .toList();

    final recent = history
        .where((t) => date.difference(t.date).inDays.abs() <= 4)
        .map((t) => t.topic)
        .toSet();

    final fresh = pool
        .where((t) => !recent.contains(t.kk) && !recent.contains(t.ru))
        .toList();
    final focus = TopicCatalog.focusFor(user.level)
        .where((t) => !recent.contains(t.kk) && !recent.contains(t.ru))
        .toList();

    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    final ordered = <Topic>[...weak];
    for (final list in [focus, fresh, pool]) {
      final copy = [...list]..shuffle(random);
      for (final topic in copy) {
        if (!ordered.any((t) => t.id == topic.id)) ordered.add(topic);
      }
    }
    return ordered;
  }

  TaskDifficulty _difficultyFor(
    AppUser user,
    ProgressStats stats,
    List<StudyTask> history,
    PaceReport pace,
  ) {
    final base = switch (user.level) {
      PrepLevel.beginner => TaskDifficulty.easy,
      PrepLevel.middle => TaskDifficulty.medium,
      PrepLevel.advanced => TaskDifficulty.hard,
    };

    final recent = history
        .where((t) => DateTime.now().difference(t.date).inDays <= 7)
        .toList();
    if (recent.length < 4) return base;

    final done = recent.where((t) => t.isDone).length / recent.length;
    final index = TaskDifficulty.values.indexOf(base);
    if (pace.pace == Pace.slow) {
      return TaskDifficulty.values[max(index - 1, 0)];
    }
    if (done >= 0.8 && stats.testAverage >= 0.7) {
      return TaskDifficulty.values[min(index + 1, 2)];
    }
    if (done <= 0.4) return TaskDifficulty.values[max(index - 1, 0)];
    if (pace.pace == Pace.fast && done >= 0.7) {
      return TaskDifficulty.values[min(index + 1, 2)];
    }
    return base;
  }

  List<StudyTask> _buildTasks({
    required AppUser user,
    required DateTime date,
    required int budget,
    required List<Topic> topics,
    required TaskDifficulty base,
    required bool isKz,
  }) {
    if (budget < 20 || topics.isEmpty) return [];

    final tasks = <StudyTask>[];
    final day = TimeUtils.dayStart(date);
    final deadline = day.add(const Duration(hours: 23, minutes: 59));
    final kinds = _kindOrder(base);
    var spent = 0;
    var index = 0;

    while (spent < budget && index < 5) {
      final kind = kinds[index % kinds.length];
      final topic = topics[index % topics.length];
      final difficulty = _shiftDifficulty(base, index);
      final duration = _durationFor(difficulty, kind);
      if (spent + duration > budget && tasks.isNotEmpty) break;

      tasks.add(StudyTask(
        id: _uuid.v4(),
        userId: user.id,
        title: _title(kind, topic, difficulty, isKz),
        description: _description(kind, topic, difficulty, isKz),
        topic: topic.name(isKz),
        difficulty: difficulty,
        durationMinutes: duration,
        date: day,
        deadline: deadline,
        createdAt: DateTime.now(),
      ));
      spent += duration;
      index++;
    }
    return tasks;
  }

  List<String> _kindOrder(TaskDifficulty base) => switch (base) {
        TaskDifficulty.easy => const ['theory', 'practice', 'test', 'practice'],
        TaskDifficulty.medium => const [
            'practice',
            'theory',
            'practice',
            'test'
          ],
        TaskDifficulty.hard => const [
            'practice',
            'practice',
            'contest',
            'review'
          ],
      };

  TaskDifficulty _shiftDifficulty(TaskDifficulty base, int index) {
    final position = TaskDifficulty.values.indexOf(base);
    if (index == 0) return TaskDifficulty.values[max(position - 1, 0)];
    if (index >= 3) return TaskDifficulty.values[min(position + 1, 2)];
    return base;
  }

  int _durationFor(TaskDifficulty difficulty, String kind) {
    final base = switch (difficulty) {
      TaskDifficulty.easy => 25,
      TaskDifficulty.medium => 40,
      TaskDifficulty.hard => 55,
    };
    if (kind == 'test') return 20;
    if (kind == 'review') return 30;
    return base;
  }

  int _taskCount(TaskDifficulty difficulty) => switch (difficulty) {
        TaskDifficulty.easy => 3,
        TaskDifficulty.medium => 4,
        TaskDifficulty.hard => 5,
      };

  String _title(
      String kind, Topic topic, TaskDifficulty difficulty, bool isKz) {
    final name = topic.name(isKz);
    final count = _taskCount(difficulty);
    return switch (kind) {
      'theory' =>
        isKz ? '$name: теорияны талдау' : '$name: разбор теории',
      'test' => isKz ? '$name бойынша мини-тест' : 'Мини-тест по теме «$name»',
      'contest' => isKz
          ? '$name: уақытқа қарсы жаттығу'
          : '$name: тренировка на время',
      'review' =>
        isKz ? '$name: қателермен жұмыс' : '$name: работа над ошибками',
      _ => isKz
          ? '$name: $count есеп шығару'
          : '$name: решить $count задач(и)',
    };
  }

  String _description(
      String kind, Topic topic, TaskDifficulty difficulty, bool isKz) {
    final name = topic.name(isKz);
    final count = _taskCount(difficulty);
    return switch (kind) {
      'theory' => isKz
          ? '«$name» тақырыбының негізгі идеясын оқып шық, конспект жаз және 1 үлгі есепті қолмен талдап көр.'
          : 'Изучи основную идею темы «$name», сделай конспект и разбери один пример решения вручную.'
      ,
      'test' => isKz
          ? '«$name» бойынша қысқа тест тапсыр. Қателескен сұрақтарды бөлек жазып ал.'
          : 'Пройди короткий тест по теме «$name». Ошибочные вопросы выпиши отдельно.'
      ,
      'contest' => isKz
          ? 'Таймер қой және «$name» бойынша есептерді олимпиада форматында шығар. Уақытты бақыла.'
          : 'Поставь таймер и реши задачи по теме «$name» в олимпиадном формате. Следи за временем.'
      ,
      'review' => isKz
          ? 'Соңғы қателеріңді қайта қарап, «$name» бойынша дұрыс шешімді өз бетіңше қайта жаз.'
          : 'Пересмотри последние ошибки и заново напиши правильное решение по теме «$name».'
      ,
      _ => isKz
          ? '«$name» тақырыбы бойынша $count есеп шығар. Әр есептің шешімін кодта және тестілеп көр.'
          : 'Реши $count задач(и) по теме «$name». Каждое решение напиши кодом и протестируй.'
    };
  }

  List<ScheduleItem> buildSchedule({
    required AppUser user,
    required DateTime date,
    required List<StudyTask> tasks,
    required L10n l,
  }) {
    final day = TimeUtils.dayStart(date);
    final items = <ScheduleItem>[];

    for (final block in FreeTimeEngine.busyBlocks(user, date, l)) {
      items.add(ScheduleItem(
        id: _uuid.v4(),
        userId: user.id,
        date: day,
        startTime: block.startLabel,
        endTime: block.endLabel,
        type: block.type,
        title: block.title,
      ));
    }

    final windows = FreeTimeEngine.freeWindows(user, date, l);
    final queue = [...tasks];
    for (final window in windows) {
      var cursor = window.start;
      while (queue.isNotEmpty && cursor + queue.first.durationMinutes <= window.end) {
        final task = queue.removeAt(0);
        final end = cursor + task.durationMinutes;
        items.add(ScheduleItem(
          id: _uuid.v4(),
          userId: user.id,
          date: day,
          startTime: TimeUtils.fromMinutes(cursor),
          endTime: TimeUtils.fromMinutes(end),
          type: SlotType.study,
          title: task.title,
          taskId: task.id,
        ));
        cursor = end + 10;
      }
      if (window.end - cursor >= 20) {
        items.add(ScheduleItem(
          id: _uuid.v4(),
          userId: user.id,
          date: day,
          startTime: TimeUtils.fromMinutes(cursor),
          endTime: window.endLabel,
          type: SlotType.free,
          title: l.t('Бос уақыт', 'Свободное время'),
        ));
      }
    }

    items.sort((a, b) => TimeUtils.toMinutes(a.startTime)
        .compareTo(TimeUtils.toMinutes(b.startTime)));
    return items;
  }

  @override
  Future<String> advice({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> today,
    required bool isKz,
  }) async {
    final l = L10n(isKz ? AppLang.kk : AppLang.ru);
    final name = user.name.split(' ').first;
    final weak = stats.weakTopics;
    final minutes = today.fold<int>(0, (sum, t) => sum + t.durationMinutes);

    if (today.isEmpty) {
      return l.t(
        '$name, бүгін бос уақыт аз болып тұр. Кем дегенде 20 минут бөліп, бір жеңіл есеп шығарсаң, серия үзілмейді.',
        '$name, сегодня свободного времени мало. Выдели хотя бы 20 минут на одну лёгкую задачу — серия не прервётся.',
      );
    }
    if (weak.isNotEmpty) {
      final topic = weak.first.key;
      return l.t(
        '$name, «$topic» тақырыбы әлсіз тұр. Бүгінгі ${l.duration(minutes)} дайындықтың алғашқы бөлігін осы тақырыпқа арна.',
        '$name, тема «$topic» пока слабое место. Первую часть сегодняшних ${l.duration(minutes)} подготовки посвяти именно ей.',
      );
    }
    if (stats.streakDays >= 3) {
      return l.t(
        '$name, қатарынан ${stats.streakDays} күн дайындалып жүрсің. Бүгін де ${l.duration(minutes)} уақыт бөлсең, ырғақ сақталады.',
        '$name, ты занимаешься ${stats.streakDays} дней подряд. Удели сегодня ${l.duration(minutes)} — и ритм сохранится.',
      );
    }
    return l.t(
      '$name, бүгінгі жоспар дайын: ${today.length} тапсырма, ${l.duration(minutes)}. Ең қиынынан баста, ми сергек кезде тиімдірек.',
      '$name, план на сегодня готов: ${today.length} задания, ${l.duration(minutes)}. Начни с самого сложного — на свежую голову эффективнее.',
    );
  }

  @override
  Future<String> reply({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> today,
    required List<ChatMessage> history,
    required String message,
    required bool isKz,
  }) async {
    final l = L10n(isKz ? AppLang.kk : AppLang.ru);
    final text = message.toLowerCase();
    final pending = today.where((t) => !t.isDone).toList();

    bool has(List<String> keys) => keys.any(text.contains);

    if (has(['не оқы', 'что учить', 'бүгін не', 'что делать', 'неден баста'])) {
      if (pending.isEmpty) {
        return l.t(
          'Бүгінгі тапсырмалар аяқталды. Қаласаң, әлсіз тақырып бойынша қосымша 20 минут жаттығу жасай аласың.',
          'Задания на сегодня выполнены. Если хочешь, добавь 20 минут практики по слабой теме.',
        );
      }
      final task = pending.first;
      return l.t(
        'Бүгін «${task.title}» тапсырмасынан баста. Оған ${l.duration(task.durationMinutes)} кетеді, дедлайн — бүгін кешке.',
        'Начни с задания «${task.title}». На него уйдёт ${l.duration(task.durationMinutes)}, дедлайн — сегодня вечером.',
      );
    }

    if (has(['прогресс', 'прогрес', 'нәтиже', 'статист'])) {
      final percent = (stats.percentage * 100).round();
      return l.t(
        'Қазіргі прогресс: $percent%. Орындалған тапсырма — ${stats.completedTasks}/${stats.totalTasks}, серия — ${stats.streakDays} күн.',
        'Текущий прогресс: $percent%. Выполнено заданий — ${stats.completedTasks}/${stats.totalTasks}, серия — ${stats.streakDays} дн.',
      );
    }

    if (has(['әлсіз', 'слаб', 'қиын тақырып', 'что подтянуть'])) {
      final weak = stats.weakTopics;
      if (weak.isEmpty) {
        return l.t(
          'Әзірге әлсіз тақырып байқалмайды. Бірнеше тест тапсырсаң, талдау дәлірек болады.',
          'Слабых тем пока не видно. Пройди несколько тестов — анализ станет точнее.',
        );
      }
      final list = weak.map((e) => e.key).join(', ');
      return l.t(
        'Күшейту қажет тақырыптар: $list. Әрқайсысына аптасына кемінде 2 сессия бөл.',
        'Стоит подтянуть темы: $list. Выдели на каждую минимум 2 занятия в неделю.',
      );
    }

    final topic = TopicCatalog.all.where((t) {
      final key = isKz ? t.kk : t.ru;
      return text.contains(key.toLowerCase().split(' ').first);
    }).toList();
    if (topic.isNotEmpty) {
      final name = topic.first.name(isKz);
      return l.t(
        '«$name» тақырыбын үш қадаммен меңгер: 1) негізгі идеяны оқы, 2) бір үлгі есепті талдап шық, 3) 3 есеп өз бетіңше шығар. Қаласаң, осы тақырыпты бүгінгі жоспарға қосамын.',
        'Тему «$name» разбирай в три шага: 1) прочитай основную идею, 2) разбери один пример, 3) реши 3 задачи сам. Могу добавить эту тему в сегодняшний план.',
      );
    }

    return l.t(
      'Сұрағыңды түсіндім. Нақтырақ жауап беру үшін тақырыпты немесе есептің шартын жазып жібер — қадаммен талдап берейін.',
      'Понял вопрос. Чтобы ответить точнее, пришли тему или условие задачи — разберу пошагово.',
    );
  }
}
