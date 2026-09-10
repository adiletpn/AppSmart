import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_header.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile_setup/profile_setup_screen.dart';
import '../progress/statistics_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final user = app.user;
    if (user == null) return const SizedBox.shrink();
    final stats = app.stats;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Профиль', 'Профиль'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            GradientCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _MiniStat(
                        value: '${user.grade}',
                        label: l.t('сынып', 'класс'),
                      ),
                      _MiniStat(
                        value: '${stats.completedTasks}',
                        label: l.t('тапсырма', 'заданий'),
                      ),
                      _MiniStat(
                        value: '${stats.streakDays}',
                        label: l.t('күн серия', 'дней серия'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Дайындық', 'Подготовка')),
            SurfaceCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    label: l.t('Олимпиада', 'Олимпиада'),
                    value: user.olympiad,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.bar_chart,
                    label: l.t('Деңгей', 'Уровень'),
                    value: l.level(user.level),
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: l.t('Күніне дайындық', 'Занятий в день'),
                    value: l.duration(user.dailyStudyMinutes),
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: l.t('Дайындық терезесі', 'Окно подготовки'),
                    value: '${user.freeFrom} – ${user.freeTo}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Басқару', 'Управление')),
            _MenuTile(
              icon: Icons.edit_outlined,
              title: l.t('Профильді өңдеу', 'Редактировать профиль'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSetupScreen(editing: true),
                ),
              ),
            ),
            _MenuTile(
              icon: Icons.query_stats,
              title: l.t('Статистика', 'Статистика'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.notifications_none,
              title: l.t('Хабарламалар', 'Уведомления'),
              badge: app.unreadCount,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              title: l.t('Параметрлер', 'Настройки'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await app.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              icon: const Icon(Icons.logout, size: 19),
              label: Text(l.t('Шығу', 'Выйти')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
