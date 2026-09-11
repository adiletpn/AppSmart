import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import 'add_test_sheet.dart';
import 'statistics_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final stats = app.stats;
    final topics = stats.topicScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Прогресс', 'Прогресс')),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddTestSheet(),
            ),
            icon: const Icon(Icons.add_chart),
            tooltip: l.t('Тест нәтижесі', 'Результат теста'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
            icon: const Icon(Icons.query_stats),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            GradientCard(
              child: Row(
                children: [
                  ProgressRing(
                    value: stats.percentage,
                    size: 104,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(stats.percentage * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l.t('жалпы', 'общий'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('Жалпы прогресс', 'Общий прогресс'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.t(
                            '${stats.completedTasks} тапсырма орындалды',
                            'Выполнено заданий: ${stats.completedTasks}',
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        Text(
                          l.t(
                            '${stats.totalTasks - stats.completedTasks} тапсырма қалды',
                            'Осталось: ${stats.totalTasks - stats.completedTasks}',
                          ),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.local_fire_department,
                    value: '${stats.streakDays}',
                    label: l.t('Қатарынан күн', 'Дней подряд'),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    icon: Icons.event_available,
                    value: '${stats.activeDays}',
                    label: l.t('Дайындық күні', 'Дней подготовки'),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    icon: Icons.school_outlined,
                    value: '${(stats.testAverage * 100).round()}%',
                    label: l.t('Тест орташасы', 'Средний тест'),
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            if (stats.hasTracked) ...[
              const SizedBox(height: 26),
              SectionHeader(
                title: l.t('Жоспар мен факт', 'План и факт'),
                subtitle: l.t('Таймермен өлшенген уақыт',
                    'Время, замеренное таймером'),
              ),
              SurfaceCard(
                child: Column(
                  children: [
                    _PlanFactRow(
                      label: l.t('Жоспарланған', 'Запланировано'),
                      value: l.duration(stats.studyMinutes),
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _PlanFactRow(
                      label: l.t('Нақты жұмсалған', 'Фактически потрачено'),
                      value: l.duration(stats.trackedMinutes),
                      color: stats.trackedMinutes > stats.studyMinutes
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (stats.accuracy / 2).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                        color: stats.accuracy > 1.2
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stats.accuracy > 1.2
                          ? l.t(
                              'Тапсырмаларға жоспардан ұзақ уақыт кетіп жатыр.',
                              'На задания уходит больше времени, чем в плане.',
                            )
                          : stats.accuracy < 0.7
                              ? l.t(
                                  'Жоспардан жылдам бітіріп жатырсың — күрделілікті көтеруге болады.',
                                  'Ты справляешься быстрее плана — можно повысить сложность.',
                                )
                              : l.t(
                                  'Жоспар нақты уақытыңа сәйкес келеді.',
                                  'План совпадает с реальным временем.',
                                ),
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            SectionHeader(
              title: l.t('Апталық белсенділік', 'Активность за неделю'),
              subtitle: l.t('Күніне орындалған тапсырма',
                  'Выполнено заданий по дням'),
            ),
            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(8, 20, 14, 8),
              child: SizedBox(
                height: 170,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (stats.weeklyCompleted.reduce((a, b) => a > b ? a : b) + 2)
                        .toDouble(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.07),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              l.weekdays[value.toInt() % 7],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: List.generate(
                      7,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: stats.weeklyCompleted[index].toDouble(),
                            width: 16,
                            borderRadius: BorderRadius.circular(6),
                            gradient: AppColors.cardGradient,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: l.t('Тақырыптар бойынша', 'По темам'),
              subtitle: l.t('Орындау және тест нәтижесі',
                  'Выполнение и результаты тестов'),
            ),
            if (topics.isEmpty)
              SurfaceCard(
                child: Text(
                  l.t(
                    'Әзірге дерек жоқ. Тапсырмаларды орындай баста.',
                    'Данных пока нет. Начни выполнять задания.',
                  ),
                  style: const TextStyle(fontSize: 13.5),
                ),
              )
            else
              ...topics.take(8).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(entry.value * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: entry.value >= 0.7
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: entry.value,
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.08),
                              color: entry.value >= 0.7
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PlanFactRow extends StatelessWidget {
  const _PlanFactRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
