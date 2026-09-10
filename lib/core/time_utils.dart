import 'package:flutter/material.dart';

class TimeUtils {
  static int toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  static String fromMinutes(int minutes) {
    final m = ((minutes % 1440) + 1440) % 1440;
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  static String fromTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static TimeOfDay toTimeOfDay(String hhmm) {
    final m = toMinutes(hhmm);
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

}
