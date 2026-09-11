import '../../core/l10n.dart';
import '../models/app_user.dart';
import '../models/progress_stats.dart';
import '../models/study_task.dart';
import '../models/test_result.dart';

class ProgressReport {
  const ProgressReport._();

  static String build({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> tasks,
    required List<TestResult> tests,
    required L10n l,
    required DateTime now,
  }) {
    final lines = <String>[];

    lines.add('SMART MENTOR — ${l.t('дайындық есебі', 'отчёт о подготовке')}');
    lines.add(l.longDate(now));
    lines.add('');

    lines.add(l.t('ОҚУШЫ', 'УЧЕНИК'));
    lines.add('${l.t('Аты-жөні', 'Имя')}: ${user.name}');
    lines.add('${l.t('Сынып', 'Класс')}: ${user.grade}');
    if (user.olympiad.isNotEmpty) {
      lines.add('${l.t('Олимпиада', 'Олимпиада')}: ${user.olympiad}');
    }
    lines.add('${l.t('Деңгей', 'Уровень')}: ${l.level(user.level)}');
    lines.add('');

    lines.add(l.t('ЖАЛПЫ НӘТИЖЕ', 'ОБЩИЙ РЕЗУЛЬТАТ'));
    lines.add(
      '${l.t('Орындалған тапсырмалар', 'Выполнено заданий')}: '
      '${stats.completedTasks} / ${stats.totalTasks} '
      '(${(stats.percentage * 100).round()}%)',
    );
    lines.add(
      '${l.t('Дайындық күндері', 'Дней подготовки')}: ${stats.activeDays}',
    );
    lines.add(
      '${l.t('Қатарынан күн', 'Дней подряд')}: ${stats.streakDays}',
    );
    lines.add(
      '${l.t('Жоспарланған уақыт', 'Запланировано времени')}: '
      '${l.duration(stats.studyMinutes)}',
    );
    if (stats.hasTracked) {
      lines.add(
        '${l.t('Нақты жұмсалған', 'Фактически затрачено')}: '
        '${l.duration(stats.trackedMinutes)} '
        '(${(stats.accuracy * 100).round()}% ${l.t('жоспардан', 'от плана')})',
      );
    }
    if (tests.isNotEmpty) {
      lines.add(
        '${l.t('Тест орташасы', 'Средний балл тестов')}: '
        '${(stats.testAverage * 100).round()}%',
      );
    }
    lines.add('');

    final strong = stats.strongTopics;
    if (strong.isNotEmpty) {
      lines.add(l.t('МЫҚТЫ ТАҚЫРЫПТАР', 'СИЛЬНЫЕ ТЕМЫ'));
      for (final entry in strong) {
        lines.add('  ${entry.key} — ${(entry.value * 100).round()}%');
      }
      lines.add('');
    }

    final weak = stats.weakTopics;
    if (weak.isNotEmpty) {
      lines.add(l.t('КҮШЕЙТУ ҚАЖЕТ', 'ТРЕБУЕТ ВНИМАНИЯ'));
      for (final entry in weak) {
        lines.add('  ${entry.key} — ${(entry.value * 100).round()}%');
      }
      lines.add('');
    }

    if (tests.isNotEmpty) {
      lines.add(l.t('ТЕСТ НӘТИЖЕЛЕРІ', 'РЕЗУЛЬТАТЫ ТЕСТОВ'));
      final recent = tests.reversed.take(10);
      for (final test in recent) {
        lines.add(
          '  ${l.shortDate(test.date)}  ${test.topic} — '
          '${test.score}/${test.total}',
        );
      }
      lines.add('');
    }

    final done = tasks.where((t) => t.isDone).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (done.isNotEmpty) {
      lines.add(l.t('СОҢҒЫ ОРЫНДАЛҒАН ТАПСЫРМАЛАР',
          'ПОСЛЕДНИЕ ВЫПОЛНЕННЫЕ ЗАДАНИЯ'));
      for (final task in done.take(10)) {
        final spent =
            task.spentMinutes > 0 ? ' · ${l.duration(task.spentMinutes)}' : '';
        lines.add('  ${l.shortDate(task.date)}  ${task.title}$spent');
      }
      lines.add('');
    }

    lines.add(l.t(
      'Есеп SMART MENTOR қосымшасында жасалды.',
      'Отчёт сформирован в приложении SMART MENTOR.',
    ));

    return lines.join('\n');
  }
}
