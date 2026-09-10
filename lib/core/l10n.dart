import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../data/models/app_notification.dart';
import '../data/models/app_user.dart';
import '../data/models/schedule_item.dart';
import '../data/models/study_task.dart';
import '../state/settings_state.dart';

enum AppLang { kk, ru }

extension AppLangX on AppLang {
  String get title => this == AppLang.kk ? 'Қазақша' : 'Русский';
  String get code => name;
}

class L10n {
  final AppLang lang;
  const L10n(this.lang);

  bool get isKz => lang == AppLang.kk;

  String t(String kk, String ru) => lang == AppLang.kk ? kk : ru;

  String difficulty(TaskDifficulty value) => switch (value) {
        TaskDifficulty.easy => t('Жеңіл', 'Лёгкая'),
        TaskDifficulty.medium => t('Орташа', 'Средняя'),
        TaskDifficulty.hard => t('Күрделі', 'Сложная'),
      };

  String taskStatus(TaskStatus value) => switch (value) {
        TaskStatus.pending => t('Жоспарда', 'В плане'),
        TaskStatus.inProgress => t('Орындалуда', 'В процессе'),
        TaskStatus.done => t('Орындалды', 'Выполнено'),
        TaskStatus.missed => t('Өткізіп алды', 'Просрочено'),
      };

  String slotType(SlotType value) => switch (value) {
        SlotType.school => t('Сабақ', 'Уроки'),
        SlotType.sleep => t('Ұйқы', 'Сон'),
        SlotType.meal => t('Тамақтану', 'Приём пищи'),
        SlotType.extra => t('Қосымша сабақ', 'Доп. занятие'),
        SlotType.study => t('Дайындық', 'Подготовка'),
        SlotType.free => t('Бос уақыт', 'Свободное время'),
      };

  String level(PrepLevel value) => switch (value) {
        PrepLevel.beginner => t('Бастауыш', 'Начальный'),
        PrepLevel.middle => t('Орта', 'Средний'),
        PrepLevel.advanced => t('Жоғары', 'Высокий'),
      };

  String levelHint(PrepLevel value) => switch (value) {
        PrepLevel.beginner =>
          t('Жаңа бастадым, негізді бекітемін', 'Начинаю, укрепляю базу'),
        PrepLevel.middle =>
          t('Мектеп кезеңіне қатысқанмын', 'Участвовал в школьном этапе'),
        PrepLevel.advanced =>
          t('Облыстық/республикалық деңгей', 'Областной/республиканский уровень'),
      };

  String notificationType(NotificationType value) => switch (value) {
        NotificationType.reminder => t('Еске салу', 'Напоминание'),
        NotificationType.tasksReady => t('Тапсырмалар', 'Задания'),
        NotificationType.deadline => t('Дедлайн', 'Дедлайн'),
        NotificationType.streak => t('Серия', 'Серия'),
        NotificationType.weekly => t('Апталық есеп', 'Итоги недели'),
      };

  List<String> get weekdays => isKz
      ? const ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жк']
      : const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  List<String> get months => isKz
      ? const [
          'қаңтар',
          'ақпан',
          'наурыз',
          'сәуір',
          'мамыр',
          'маусым',
          'шілде',
          'тамыз',
          'қыркүйек',
          'қазан',
          'қараша',
          'желтоқсан'
        ]
      : const [
          'января',
          'февраля',
          'марта',
          'апреля',
          'мая',
          'июня',
          'июля',
          'августа',
          'сентября',
          'октября',
          'ноября',
          'декабря'
        ];

  String longDate(DateTime date) =>
      '${date.day} ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}';

  String duration(int minutes) {
    if (minutes < 60) return '$minutes ${t('мин', 'мин')}';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hLabel = t('сағ', 'ч');
    return m == 0 ? '$h $hLabel' : '$h $hLabel $m ${t('мин', 'мин')}';
  }

  String greeting(DateTime now) {
    if (now.hour < 12) return t('Қайырлы таң', 'Доброе утро');
    if (now.hour < 18) return t('Қайырлы күн', 'Добрый день');
    return t('Қайырлы кеш', 'Добрый вечер');
  }
}

extension L10nContext on BuildContext {
  L10n get l => L10n(watch<SettingsState>().lang);
  L10n get lRead => L10n(read<SettingsState>().lang);
}
