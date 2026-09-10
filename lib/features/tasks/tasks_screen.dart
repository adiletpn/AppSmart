import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../widgets/ai_busy_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import 'add_task_sheet.dart';
import 'task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final today = app.todayTasks;

    final filtered = switch (_filter) {
      1 => today.where((t) => !t.isDone).toList(),
      2 => today.where((t) => t.isDone).toList(),
      _ => today,
    };

    final labels = [
      l.t('Барлығы', 'Все'),
      l.t('Қалғаны', 'Осталось'),
      l.t('Орындалды', 'Готово'),
    ];

    final minutes =
        today.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final doneMinutes = today
        .where((t) => t.isDone)
        .fold<int>(0, (sum, t) => sum + t.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Күнделікті тапсырмалар', 'Ежедневные задания')),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddTaskSheet(),
            ),
            icon: const Icon(Icons.add),
            tooltip: l.t('Тапсырма қосу', 'Добавить задание'),
          ),
          IconButton(
            onPressed: app.busy
                ? null
                : () => app.generatePlan(DateTime.now(), force: true),
            icon: app.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l.t('Жаңарту', 'Обновить'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('Бүгінгі жүктеме', 'Нагрузка на сегодня'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l.duration(doneMinutes)} / ${l.duration(minutes)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        value: minutes == 0 ? 0 : doneMinutes / minutes,
                        strokeWidth: 6,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AiBusyBanner(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(labels.length, (index) {
                  final selected = _filter == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(labels[index]),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = index),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.checklist,
                      title: l.t('Тапсырма жоқ', 'Заданий нет'),
                      subtitle: l.t(
                        'AI жоспарын жаңартып, бүгінге тапсырма ала аласың.',
                        'Обнови план — AI подберёт задания на сегодня.',
                      ),
                      actionLabel: l.t('Жоспар құру', 'Построить план'),
                      onAction: () =>
                          app.generatePlan(DateTime.now(), force: true),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => Dismissible(
                        key: ValueKey(filtered[index].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: AppColors.danger),
                        ),
                        onDismissed: (_) => app.deleteTask(filtered[index].id),
                        child: TaskCard(task: filtered[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
