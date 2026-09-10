import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../../data/models/schedule_item.dart';
import '../../state/app_state.dart';
import '../../widgets/ai_busy_banner.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../tasks/task_card.dart';
import '../tasks/tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final user = app.user;
    if (user == null) return const SizedBox.shrink();

    final today = app.todayTasks;
    final done = today.where((t) => t.isDone).length;
    final ratio = today.isEmpty ? 0.0 : done / today.length;
    final stats = app.stats;
    final schedule = app.scheduleFor(DateTime.now());
    final now = TimeUtils.toMinutes(
      TimeUtils.fromTimeOfDay(TimeOfDay.fromDateTime(DateTime.now())),
    );
    final upcoming = schedule
        .where((s) => TimeUtils.toMinutes(s.endTime) >= now)
        .take(3)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => app.generatePlan(DateTime.now(), force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.greeting(DateTime.now()),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          user.name.split(' ').first,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none),
                      ),
                      if (app.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${app.unreadCount}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const AiBusyBanner(),
              GradientCard(
                child: Row(
                  children: [
                    ProgressRing(
                      value: ratio,
                      size: 92,
                      center: Text(
                        '${(ratio * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('Бүгінгі прогресс', 'Прогресс за сегодня'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.t(
                              '$done / ${today.length} тапсырма орындалды',
                              'Выполнено $done из ${today.length} заданий',
                            ),
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, size: 17),
                              const SizedBox(width: 5),
                              Text(
                                l.t(
                                  'Серия: ${stats.streakDays} күн',
                                  'Серия: ${stats.streakDays} дн.',
                                ),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AdviceCard(advice: app.advice),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.timer_outlined,
                      value: l.duration(app.freeMinutesFor(DateTime.now())),
                      label: l.t('Бүгінгі бос уақыт', 'Свободное время'),
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.check_circle_outline,
                      value: '${stats.completedTasks}',
                      label: l.t('Барлық орындалған', 'Всего выполнено'),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatTile(
                      icon: Icons.menu_book_outlined,
                      value: l.duration(stats.studyMinutes),
                      label: l.t('Оқу уақыты', 'Время учёбы'),
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: l.t('Бүгінгі жоспар', 'План на сегодня'),
                subtitle: l.longDate(DateTime.now()),
              ),
              if (upcoming.isEmpty)
                _EmptyLine(text: l.t('Жоспар бос', 'План пуст'))
              else
                ...upcoming.map((item) => _ScheduleLine(item: item)),
              const SizedBox(height: 24),
              SectionHeader(
                title: l.t('Бүгінгі тапсырмалар', 'Задания на сегодня'),
                actionLabel: l.t('Барлығы', 'Все'),
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TasksScreen()),
                ),
              ),
              if (today.isEmpty)
                _EmptyLine(
                  text: l.t('Тапсырма жоқ', 'Заданий нет'),
                )
              else
                ...today.take(3).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(task: task),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice});

  final String advice;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (advice.isEmpty) return const SizedBox.shrink();
    return SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Mentor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.t('кеңесі', 'советует'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  advice,
                  style: const TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final color = switch (item.type) {
      SlotType.study => AppColors.primary,
      SlotType.school => AppColors.purple,
      SlotType.sleep => AppColors.lightMuted,
      SlotType.meal => AppColors.warning,
      SlotType.extra => AppColors.accent,
      SlotType.free => AppColors.success,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              item.startTime,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${l.slotType(item.type)} · ${item.startTime}–${item.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 18,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
