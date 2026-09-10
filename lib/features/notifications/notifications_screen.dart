import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/app_notification.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().markNotificationsRead();
    });
  }

  Color _colorFor(NotificationType type) => switch (type) {
        NotificationType.reminder => AppColors.primary,
        NotificationType.tasksReady => AppColors.success,
        NotificationType.deadline => AppColors.danger,
        NotificationType.streak => AppColors.warning,
        NotificationType.weekly => AppColors.purple,
      };

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.reminder => Icons.alarm,
        NotificationType.tasksReady => Icons.task_alt,
        NotificationType.deadline => Icons.timer_off,
        NotificationType.streak => Icons.local_fire_department,
        NotificationType.weekly => Icons.bar_chart,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final items = app.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Хабарламалар', 'Уведомления')),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              onPressed: app.clearNotifications,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none,
                title: l.t('Хабарлама жоқ', 'Уведомлений нет'),
                subtitle: l.t(
                  'Жоспар құрылғанда және дедлайн жақындағанда хабарлама келеді.',
                  'Придут, когда появится план или приблизится дедлайн.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final item = items[index];
                  final color = _colorFor(item.type);
                  return SurfaceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_iconFor(item.type),
                              size: 20, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${l.notificationType(item.type)} · ${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
