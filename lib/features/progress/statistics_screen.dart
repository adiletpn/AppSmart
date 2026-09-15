import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_header.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  /// Тақырып аты диаграммаға сыймайды — бірінші сөзін ғана қалдырамыз.
  static String _shortName(String name) {
    final first = name.split(' ').first;
    return first.length <= 12 ? first : '${first.substring(0, 11)}…';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final stats = app.stats;
    final tests = app.tests.reversed.toList();
    final weak = stats.weakTopics;
    final strong = stats.strongTopics;

    // Ең көп кездескен тақырыптар: диаграммада 6-дан артық баған оқылмайды.
    final byTopic = stats.topicScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chartTopics = byTopic.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Статистика', 'Статистика'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            SectionHeader(
              title: l.t('Тест динамикасы', 'Динамика тестов'),
              subtitle: l.t('Соңғы нәтижелер', 'Последние результаты'),
            ),
            if (tests.isEmpty)
              SurfaceCard(
                child: Text(
                  l.t('Тест нәтижелері әлі жоқ.',
                      'Результатов тестов пока нет.'),
                  style: const TextStyle(fontSize: 13.5),
                ),
              )
            else
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 10),
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
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
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 25,
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3.4,
                          gradient: AppColors.cardGradient,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.28),
                                AppColors.primary.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                          spots: List.generate(
                            tests.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              tests[index].percent * 100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (chartTopics.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: l.t('Тақырыптар бойынша', 'По темам'),
                subtitle: l.t('Меңгеру пайызы', 'Процент освоения'),
              ),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                child: SizedBox(
                  height: 190,
                  child: BarChart(
                    BarChartData(
                      maxY: 100,
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 25,
                            reservedSize: 34,
                            getTitlesWidget: (value, _) => Text(
                              '${value.round()}%',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, _) {
                              final index = value.round();
                              if (index < 0 || index >= chartTopics.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _shortName(chartTopics[index].key),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    height: 1.2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < chartTopics.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartTopics[i].value * 100,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                                color: chartTopics[i].value >= 0.7
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Күшейту қажет', 'Требует внимания')),
            if (weak.isEmpty)
              SurfaceCard(
                child: Text(
                  l.t('Әлсіз тақырып анықталмады.', 'Слабых тем не выявлено.'),
                  style: const TextStyle(fontSize: 13.5),
                ),
              )
            else
              ...weak.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down,
                            color: AppColors.danger, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Мықты тұстарың', 'Сильные стороны')),
            if (strong.isEmpty)
              SurfaceCard(
                child: Text(
                  l.t('Тапсырмаларды орындаған сайын мұнда тақырыптар шығады.',
                      'Темы появятся по мере выполнения заданий.'),
                  style: const TextStyle(fontSize: 13.5),
                ),
              )
            else
              ...strong.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(entry.value * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Тест тарихы', 'История тестов')),
            if (tests.isEmpty)
              EmptyState(
                icon: Icons.fact_check_outlined,
                title: l.t('Тарих бос', 'История пуста'),
                subtitle: l.t(
                  'Прогресс бетінде тест нәтижесін қоса аласың.',
                  'Добавить результат теста можно на экране прогресса.',
                ),
              )
            else
              ...tests.map(
                (test) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.topic,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l.longDate(test.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${test.score}/${test.total}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
