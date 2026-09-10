import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../../data/models/day_summary.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';

class WeekOverview extends StatelessWidget {
  const WeekOverview({
    super.key,
    required this.anchor,
    required this.onSelectDay,
  });

  final DateTime anchor;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final days = app.weekOverview(anchor);
    final totalStudy =
        days.fold<int>(0, (total, day) => total + day.studyMinutes);
    final totalDone = days.fold<int>(0, (total, day) => total + day.doneTasks);
    final totalTasks = days.fold<int>(0, (total, day) => total + day.totalTasks);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.t('Апталық жүктеме', 'Нагрузка за неделю'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$totalDone / $totalTasks',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.t(
              'Барлығы жоспарланған: ${l.duration(totalStudy)}',
              'Всего запланировано: ${l.duration(totalStudy)}',
            ),
            style: TextStyle(
              fontSize: 12.5,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          ...days.map((day) => _DayRow(
                day: day,
                selected: TimeUtils.sameDay(day.date, anchor),
                onTap: () => onSelectDay(day.date),
              )),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DaySummary day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final isToday = TimeUtils.sameDay(day.date, DateTime.now());

    final barColor = day.isEmpty
        ? scheme.onSurface.withValues(alpha: 0.18)
        : day.isComplete
            ? AppColors.success
            : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                l.weekdays[day.date.weekday - 1],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected || isToday
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : scheme.onSurface.withValues(alpha: isToday ? 0.9 : 0.55),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: day.load == 0 ? 0.02 : day.load,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Text(
                day.isEmpty ? '—' : l.duration(day.studyMinutes),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            SizedBox(
              width: 26,
              child: day.isComplete
                  ? const Icon(Icons.check_circle,
                      size: 16, color: AppColors.success)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
