import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../schedule/schedule_screen.dart';
import '../tasks/tasks_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      final settings = context.read<SettingsState>();
      app.generatePlan(DateTime.now()).then((_) {
        app.refreshAdvice();
        app.syncReminders(
          reminders: settings.remindersEnabled,
          deadlines: settings.deadlineAlerts,
          weekly: settings.weeklyReport,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    const pages = [
      HomeScreen(),
      ScheduleScreen(),
      TasksScreen(),
      ProgressScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.t('Басты', 'Главная'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l.t('Жоспар', 'План'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l.t('Тапсырма', 'Задания'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l.t('Прогресс', 'Прогресс'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l.t('Профиль', 'Профиль'),
          ),
        ],
      ),
    );
  }
}
