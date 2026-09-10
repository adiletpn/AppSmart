import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/study_task.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/pill.dart';
import '../../widgets/section_header.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final task = app.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.t('Тапсырма табылмады', 'Задание не найдено'))),
      );
    }

    final color = switch (task.difficulty) {
      TaskDifficulty.easy => AppColors.success,
      TaskDifficulty.medium => AppColors.warning,
      TaskDifficulty.hard => AppColors.danger,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Тапсырма', 'Задание')),
        actions: [
          IconButton(
            onPressed: () {
              app.deleteTask(task.id);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.topic_outlined, size: 17),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          task.topic.isEmpty
                              ? l.t('Тақырып көрсетілмеген', 'Тема не указана')
                              : task.topic,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 17),
                      const SizedBox(width: 7),
                      Text(
                        '${l.t('Дедлайн', 'Дедлайн')}: ${l.longDate(task.deadline)}',
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Pill(text: l.difficulty(task.difficulty), color: color),
                const SizedBox(width: 8),
                Pill(
                  text: l.duration(task.durationMinutes),
                  color: AppColors.primary,
                  icon: Icons.schedule,
                ),
                const SizedBox(width: 8),
                Pill(
                  text: l.taskStatus(task.status),
                  color: task.isDone ? AppColors.success : AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Сипаттама', 'Описание')),
            SurfaceCard(
              child: Text(
                task.description.isEmpty
                    ? l.t('Қосымша сипаттама жоқ', 'Дополнительного описания нет')
                    : task.description,
                style: const TextStyle(fontSize: 14, height: 1.55),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Орындау қадамдары', 'Шаги выполнения')),
            ..._steps(l).asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13.5, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 28),
            if (task.isDone)
              OutlinedButton.icon(
                onPressed: () => app.setTaskStatus(task.id, TaskStatus.pending),
                icon: const Icon(Icons.undo, size: 18),
                label: Text(l.t('Қайта ашу', 'Вернуть в работу')),
              )
            else ...[
              FilledButton.icon(
                onPressed: () => app.setTaskStatus(task.id, TaskStatus.done),
                icon: const Icon(Icons.check),
                label: Text(l.t('Орындалды', 'Выполнено')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    app.setTaskStatus(task.id, TaskStatus.inProgress),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text(l.t('Бастау', 'Начать')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _steps(L10n l) => [
        l.t('Тақырыптың негізгі идеясын қайталап шық.',
            'Повтори основную идею темы.'),
        l.t('Бір үлгі есепті талдап, шешімін қолмен жаз.',
            'Разбери пример и запиши решение вручную.'),
        l.t('Есептерді өз бетіңше шығар, кодты тестілеп көр.',
            'Реши задачи самостоятельно и протестируй код.'),
        l.t('Қателеріңді бөлек жазып ал — AI келесі жоспарға қосады.',
            'Выпиши ошибки — AI учтёт их в следующем плане.'),
      ];
}
