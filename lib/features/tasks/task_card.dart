import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/study_task.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/pill.dart';
import 'task_details_screen.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final StudyTask task;

  Color get _difficultyColor => switch (task.difficulty) {
        TaskDifficulty.easy => AppColors.success,
        TaskDifficulty.medium => AppColors.warning,
        TaskDifficulty.hard => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.read<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final done = task.isDone;

    return SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => app.setTaskStatus(
              task.id,
              done ? TaskStatus.pending : TaskStatus.done,
            ),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: done ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: done
                      ? AppColors.success
                      : scheme.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done
                        ? scheme.onSurface.withValues(alpha: 0.45)
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Pill(
                      text: l.difficulty(task.difficulty),
                      color: _difficultyColor,
                    ),
                    Pill(
                      text: l.duration(task.durationMinutes),
                      color: AppColors.primary,
                      icon: Icons.schedule,
                    ),
                    if (task.status == TaskStatus.missed)
                      Pill(
                        text: l.taskStatus(task.status),
                        color: AppColors.danger,
                        icon: Icons.error_outline,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: scheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
