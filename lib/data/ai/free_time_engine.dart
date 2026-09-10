import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../models/app_user.dart';
import '../models/schedule_item.dart';

class TimeBlock {
  final int start;
  final int end;
  final SlotType type;
  final String title;

  const TimeBlock(this.start, this.end, this.type, this.title);

  int get minutes => end - start;
  String get startLabel => TimeUtils.fromMinutes(start);
  String get endLabel => TimeUtils.fromMinutes(end);
}

class FreeTimeEngine {
  static List<TimeBlock> busyBlocks(AppUser user, DateTime date, L10n l) {
    final blocks = <TimeBlock>[];
    final sleepStart = TimeUtils.toMinutes(user.sleepStart);
    final sleepEnd = TimeUtils.toMinutes(user.sleepEnd);
    final sleepTitle = l.t('Ұйқы', 'Сон');
    if (sleepStart < sleepEnd) {
      blocks.add(TimeBlock(sleepStart, sleepEnd, SlotType.sleep, sleepTitle));
    } else {
      blocks.add(TimeBlock(0, sleepEnd, SlotType.sleep, sleepTitle));
      blocks.add(TimeBlock(sleepStart, 1440, SlotType.sleep, sleepTitle));
    }

    final isSchoolDay = date.weekday <= 5;
    if (isSchoolDay) {
      blocks.add(TimeBlock(
        TimeUtils.toMinutes(user.schoolStart),
        TimeUtils.toMinutes(user.schoolEnd),
        SlotType.school,
        l.t('Мектеп сабақтары', 'Уроки в школе'),
      ));
    }

    final meals = <String, String>{
      user.breakfast: l.t('Таңғы ас', 'Завтрак'),
      user.lunch: l.t('Түскі ас', 'Обед'),
      user.dinner: l.t('Кешкі ас', 'Ужин'),
    };
    meals.forEach((time, title) {
      final start = TimeUtils.toMinutes(time);
      blocks.add(TimeBlock(start, start + 30, SlotType.meal, title));
    });

    for (final extra in user.extraClasses) {
      if (!extra.weekdays.contains(date.weekday)) continue;
      blocks.add(TimeBlock(
        TimeUtils.toMinutes(extra.start),
        TimeUtils.toMinutes(extra.end),
        SlotType.extra,
        extra.title,
      ));
    }

    blocks.removeWhere((b) => b.end <= b.start);
    blocks.sort((a, b) => a.start.compareTo(b.start));
    return blocks;
  }

  static List<TimeBlock> mergeBusy(List<TimeBlock> blocks) {
    if (blocks.isEmpty) return [];
    final sorted = [...blocks]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <TimeBlock>[sorted.first];
    for (final block in sorted.skip(1)) {
      final last = merged.last;
      if (block.start <= last.end) {
        merged[merged.length - 1] = TimeBlock(
          last.start,
          block.end > last.end ? block.end : last.end,
          last.type,
          last.title,
        );
      } else {
        merged.add(block);
      }
    }
    return merged;
  }

  static List<TimeBlock> freeWindows(
    AppUser user,
    DateTime date,
    L10n l, {
    int minMinutes = 20,
  }) {
    final windowStart = TimeUtils.toMinutes(user.freeFrom);
    final windowEnd = TimeUtils.toMinutes(user.freeTo);
    if (windowEnd <= windowStart) return [];

    final busy = mergeBusy(busyBlocks(user, date, l));
    final free = <TimeBlock>[];
    var cursor = windowStart;
    final title = l.t('Бос уақыт', 'Свободное время');

    for (final block in busy) {
      if (block.end <= cursor) continue;
      if (block.start >= windowEnd) break;
      if (block.start > cursor) {
        final end = block.start < windowEnd ? block.start : windowEnd;
        if (end - cursor >= minMinutes) {
          free.add(TimeBlock(cursor, end, SlotType.free, title));
        }
      }
      cursor = block.end > cursor ? block.end : cursor;
      if (cursor >= windowEnd) break;
    }

    if (cursor < windowEnd && windowEnd - cursor >= minMinutes) {
      free.add(TimeBlock(cursor, windowEnd, SlotType.free, title));
    }
    return free;
  }

  static int freeMinutes(AppUser user, DateTime date, L10n l) =>
      freeWindows(user, date, l).fold(0, (sum, block) => sum + block.minutes);
}
