import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/core/l10n.dart';
import 'package:smart_mentor/core/time_utils.dart';
import 'package:smart_mentor/data/ai/free_time_engine.dart';
import 'package:smart_mentor/data/models/app_user.dart';
import 'package:smart_mentor/data/models/schedule_item.dart';

const l = L10n(AppLang.ru);

final monday = DateTime(2026, 9, 7);
final sunday = DateTime(2026, 9, 13);

AppUser user({
  String schoolStart = '08:00',
  String schoolEnd = '14:00',
  String sleepStart = '23:00',
  String sleepEnd = '07:00',
  String breakfast = '07:30',
  String lunch = '13:00',
  String dinner = '19:00',
  String freeFrom = '15:00',
  String freeTo = '22:00',
  List<ExtraClass> extraClasses = const [],
}) =>
    AppUser(
      id: 'u1',
      name: 'Тест Тестов',
      email: 'test@mail.com',
      schoolStart: schoolStart,
      schoolEnd: schoolEnd,
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      freeFrom: freeFrom,
      freeTo: freeTo,
      extraClasses: extraClasses,
      createdAt: DateTime(2026, 1, 1),
    );

String label(TimeBlock block) => '${block.startLabel}-${block.endLabel}';

void main() {
  group('busyBlocks', () {
    test('сон через полночь режется на два блока', () {
      final blocks = FreeTimeEngine.busyBlocks(user(), monday, l)
          .where((b) => b.type == SlotType.sleep)
          .toList();

      expect(blocks.length, 2);
      expect(label(blocks.first), '00:00-07:00');
      expect(label(blocks.last), '23:00-00:00');
    });

    test('сон внутри одних суток остаётся одним блоком', () {
      final blocks = FreeTimeEngine.busyBlocks(
        user(sleepStart: '01:00', sleepEnd: '09:00'),
        monday,
        l,
      ).where((b) => b.type == SlotType.sleep).toList();

      expect(blocks.length, 1);
      expect(label(blocks.first), '01:00-09:00');
    });

    test('уроки попадают в будни и пропускаются в выходные', () {
      bool hasSchool(DateTime date) => FreeTimeEngine.busyBlocks(user(), date, l)
          .any((b) => b.type == SlotType.school);

      expect(hasSchool(monday), isTrue);
      expect(hasSchool(sunday), isFalse);
    });

    test('каждый приём пищи занимает 30 минут', () {
      final meals = FreeTimeEngine.busyBlocks(user(), monday, l)
          .where((b) => b.type == SlotType.meal)
          .toList();

      expect(meals.length, 3);
      expect(meals.every((b) => b.minutes == 30), isTrue);
    });

    test('доп. занятие учитывается только в свои дни недели', () {
      final withExtra = user(
        extraClasses: const [
          ExtraClass(
            title: 'Кружок',
            start: '16:00',
            end: '17:30',
            weekdays: [1],
          ),
        ],
      );

      bool hasExtra(DateTime date) =>
          FreeTimeEngine.busyBlocks(withExtra, date, l)
              .any((b) => b.type == SlotType.extra);

      expect(hasExtra(monday), isTrue);
      expect(hasExtra(DateTime(2026, 9, 8)), isFalse);
    });
  });

  group('mergeBusy', () {
    test('склеивает пересекающиеся блоки', () {
      final merged = FreeTimeEngine.mergeBusy(const [
        TimeBlock(600, 720, SlotType.school, 'Уроки'),
        TimeBlock(700, 800, SlotType.extra, 'Кружок'),
      ]);

      expect(merged.length, 1);
      expect(label(merged.first), '10:00-13:20');
    });

    test('оставляет раздельные блоки как есть', () {
      final merged = FreeTimeEngine.mergeBusy(const [
        TimeBlock(600, 660, SlotType.school, 'Уроки'),
        TimeBlock(700, 800, SlotType.extra, 'Кружок'),
      ]);

      expect(merged.length, 2);
    });

    test('пустой список не ломает расчёт', () {
      expect(FreeTimeEngine.mergeBusy(const []), isEmpty);
    });
  });

  group('freeWindows', () {
    test('обычный учебный день: окно минус ужин', () {
      final windows = FreeTimeEngine.freeWindows(user(), monday, l);

      expect(windows.map(label).toList(), ['15:00-19:00', '19:30-22:00']);
      expect(FreeTimeEngine.freeMinutes(user(), monday, l), 390);
    });

    test('доп. занятие вырезается из окна подготовки', () {
      final withExtra = user(
        extraClasses: const [
          ExtraClass(title: 'Секция', start: '16:00', end: '17:00'),
        ],
      );

      final windows = FreeTimeEngine.freeWindows(withExtra, monday, l);

      expect(windows.map(label).toList(),
          ['15:00-16:00', '17:00-19:00', '19:30-22:00']);
      expect(FreeTimeEngine.freeMinutes(withExtra, monday, l), 330);
    });

    test('окна короче 20 минут отбрасываются', () {
      final tight = user(
        extraClasses: const [
          ExtraClass(title: 'Секция', start: '15:10', end: '18:00'),
        ],
      );

      final windows = FreeTimeEngine.freeWindows(tight, monday, l);

      expect(windows.any((b) => b.minutes < 20), isFalse);
      expect(windows.map(label).toList(), ['18:00-19:00', '19:30-22:00']);
    });

    test('полностью занятый день даёт пустой список', () {
      final busy = user(
        extraClasses: const [
          ExtraClass(title: 'Сборы', start: '15:00', end: '22:00'),
        ],
      );

      expect(FreeTimeEngine.freeWindows(busy, monday, l), isEmpty);
      expect(FreeTimeEngine.freeMinutes(busy, monday, l), 0);
    });

    test('перевёрнутое окно подготовки не ломает расчёт', () {
      final broken = user(freeFrom: '22:00', freeTo: '15:00');

      expect(FreeTimeEngine.freeWindows(broken, monday, l), isEmpty);
    });

    test('окно, пересекающее сон, обрезается по сну', () {
      final late = user(freeFrom: '21:00', freeTo: '23:59');

      expect(FreeTimeEngine.freeWindows(late, monday, l).map(label).toList(),
          ['21:00-23:00']);
    });

    test('в выходной уроки не занимают время', () {
      final schoolInsideWindow = user(schoolStart: '15:00', schoolEnd: '17:00');

      final weekday =
          FreeTimeEngine.freeMinutes(schoolInsideWindow, monday, l);
      final weekend =
          FreeTimeEngine.freeMinutes(schoolInsideWindow, sunday, l);

      expect(weekend - weekday, 120);
    });
  });

  group('TimeUtils', () {
    test('переводит время в минуты и обратно', () {
      expect(TimeUtils.toMinutes('08:30'), 510);
      expect(TimeUtils.fromMinutes(510), '08:30');
      expect(TimeUtils.fromMinutes(0), '00:00');
    });

    test('нормализует выход за сутки', () {
      expect(TimeUtils.fromMinutes(1440), '00:00');
      expect(TimeUtils.fromMinutes(-60), '23:00');
    });

    test('некорректная строка не роняет расчёт', () {
      expect(TimeUtils.toMinutes('abc'), 0);
      expect(TimeUtils.toMinutes('25'), 0);
    });
  });
}
