import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/progress_stats.dart';
import '../models/study_task.dart';
import 'free_time_engine.dart';
import 'local_mentor_ai.dart';
import 'mentor_ai.dart';
import 'pace_analyzer.dart';
import 'topic_catalog.dart';

class _ModelOption {
  const _ModelOption(this.name, this.disableThinking);

  final String name;
  final bool disableThinking;
}

class GeminiMentorAi implements MentorAi {
  GeminiMentorAi({required this.apiKey});

  final String apiKey;

  static const _models = [
    _ModelOption('gemini-2.5-flash', true),
    _ModelOption('gemini-3.6-flash', false),
    _ModelOption('gemini-flash-latest', false),
  ];

  static const _fallback = LocalMentorAi();
  static const _uuid = Uuid();
  static int _preferred = 0;

  Uri _endpoint(String model) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

  Future<String?> _ask(String system, String prompt,
      {int maxTokens = 1200}) async {
    if (apiKey.trim().isEmpty) return null;
    for (var attempt = 0; attempt < _models.length; attempt++) {
      final index = (_preferred + attempt) % _models.length;
      final text = await _request(_models[index], system, prompt, maxTokens);
      if (text != null) {
        _preferred = index;
        return text;
      }
    }
    return null;
  }

  Future<String?> _request(
    _ModelOption option,
    String system,
    String prompt,
    int maxTokens,
  ) async {
    try {
      final response = await http
          .post(
            _endpoint(option.name),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': system}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': maxTokens,
                if (option.disableThinking)
                  'thinkingConfig': {'thinkingBudget': 0},
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final parts = candidates.first['content']?['parts'];
      if (parts is! List) return null;

      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is! Map) continue;
        if (part['thought'] == true) continue;
        final text = part['text'];
        if (text is String) buffer.write(text);
      }
      final result = buffer.toString().trim();
      return result.isEmpty ? null : result;
    } on Exception {
      return null;
    }
  }

  String _paceHint(PaceReport pace) => switch (pace.pace) {
        Pace.slow =>
          'Оқушы тапсырмаларға жоспардан ${((pace.ratio - 1) * 100).round()}% көп '
              'уақыт жұмсайды. Тапсырмаларды жеңілдет және қысқарт.',
        Pace.fast =>
          'Оқушы тапсырмаларды жоспардан жылдам бітіреді '
              '(жоспардың ${(pace.ratio * 100).round()}%-ы). '
              'Күрделілікті сәл көтеруге болады.',
        _ => '',
      };

  String _profile(AppUser user, ProgressStats stats, bool isKz) {
    final weak = stats.weakTopics.map((e) => e.key).join(', ');
    final language = isKz ? 'қазақ тілінде' : 'на русском языке';
    return [
      'Оқушы: ${user.name}, ${user.grade} сынып.',
      'Олимпиада: ${user.olympiad}. Деңгейі: ${user.level.name}.',
      'Прогресс: ${stats.completedTasks}/${stats.totalTasks}, серия ${stats.streakDays}.',
      'Тест орташасы: ${(stats.testAverage * 100).round()}%.',
      if (weak.isNotEmpty) 'Әлсіз тақырыптар: $weak.',
      'Жауап тілі: $language.',
    ].join(' ');
  }

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
    if (budget < 20) {
      return _fallback.buildDay(
        user: user,
        date: date,
        stats: stats,
        history: history,
        isKz: isKz,
      );
    }

    final topics = TopicCatalog.forLevel(user.level)
        .map((t) => t.name(isKz))
        .take(14)
        .join(', ');
    final recent = history
        .where((t) => date.difference(t.date).inDays.abs() <= 3)
        .map((t) => t.title)
        .take(6)
        .join('; ');

    final answer = await _ask(
      'Сен информатика олимпиадасына дайындайтын ментор боласың. '
      'Тек JSON массивін қайтар, түсіндірмесіз, markdown белгісіз.',
      '''
${_profile(user, stats, isKz)}
${_paceHint(pace)}
Бүгінгі дайындыққа $budget минут бар.
Қолжетімді тақырыптар: $topics.
Соңғы күндері берілген тапсырмалар: ${recent.isEmpty ? 'жоқ' : recent}.

3-5 тапсырма құрастыр. Жалпы уақыты $budget минуттан аспасын.
Формат: [{"title":"","description":"","topic":"","difficulty":"easy|medium|hard","minutes":25}]
''',
      maxTokens: 1200,
    );

    final tasks = _parseTasks(answer, user, date, budget);
    if (tasks.isEmpty) {
      return _fallback.buildDay(
        user: user,
        date: date,
        stats: stats,
        history: history,
        isKz: isKz,
      );
    }

    final schedule = _fallback.buildSchedule(
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

  List<StudyTask> _parseTasks(
    String? answer,
    AppUser user,
    DateTime date,
    int budget,
  ) {
    if (answer == null) return [];
    final start = answer.indexOf('[');
    final end = answer.lastIndexOf(']');
    if (start == -1 || end <= start) return [];

    try {
      final decoded = jsonDecode(answer.substring(start, end + 1));
      if (decoded is! List) return [];
      final day = TimeUtils.dayStart(date);
      final tasks = <StudyTask>[];
      var spent = 0;

      for (final item in decoded) {
        if (item is! Map) continue;
        final title = (item['title'] as String? ?? '').trim();
        if (title.isEmpty) continue;
        final minutes = (item['minutes'] as num?)?.round() ?? 30;
        if (spent + minutes > budget && tasks.isNotEmpty) break;
        tasks.add(StudyTask(
          id: _uuid.v4(),
          userId: user.id,
          title: title,
          description: (item['description'] as String? ?? '').trim(),
          topic: (item['topic'] as String? ?? '').trim(),
          difficulty: TaskDifficulty.values.firstWhere(
            (d) => d.name == item['difficulty'],
            orElse: () => TaskDifficulty.medium,
          ),
          durationMinutes: minutes.clamp(10, 120),
          date: day,
          deadline: day.add(const Duration(hours: 23, minutes: 59)),
          createdAt: DateTime.now(),
        ));
        spent += minutes;
      }
      return tasks;
    } on Exception {
      return [];
    }
  }

  @override
  Future<String> advice({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> today,
    required bool isKz,
  }) async {
    final titles = today.map((t) => t.title).join('; ');
    final answer = await _ask(
      'Сен оқушыны қолдайтын ментор боласың. Тек 2 сөйлем жаз.',
      '${_profile(user, stats, isKz)}\nБүгінгі тапсырмалар: ${titles.isEmpty ? 'жоқ' : titles}.\n'
      'Оқушыға бүгінге қысқа әрі нақты кеңес бер.',
      maxTokens: 400,
    );
    if (answer != null) return answer;
    return _fallback.advice(
      user: user,
      stats: stats,
      today: today,
      isKz: isKz,
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
    final context = history
        .reversed
        .take(6)
        .toList()
        .reversed
        .map((m) => '${m.role == ChatRole.user ? 'Оқушы' : 'Ментор'}: ${m.text}')
        .join('\n');
    final pending = today.where((t) => !t.isDone).map((t) => t.title).join('; ');

    final answer = await _ask(
      'Сен информатика олимпиадасына дайындайтын жеке ментор боласың. '
      'Қысқа, нақты және қадаммен түсіндір. Код керек болса, Python қолдан.',
      '''
${_profile(user, stats, isKz)}
Бүгін орындалмаған тапсырмалар: ${pending.isEmpty ? 'жоқ' : pending}.

Соңғы диалог:
$context

Оқушының сұрағы: $message
''',
      maxTokens: 900,
    );
    if (answer != null) return answer;
    return _fallback.reply(
      user: user,
      stats: stats,
      today: today,
      history: history,
      message: message,
      isKz: isKz,
    );
  }
}
