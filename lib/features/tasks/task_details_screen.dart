import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/study_task.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/pill.dart';
import '../../widgets/section_header.dart';
import '../quiz/quiz_screen.dart';
import '../topics/topic_detail_screen.dart';
import 'task_timer.dart';

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
            const SizedBox(height: 22),
            if (!task.isDone) ...[
              TaskTimer(task: task),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            SectionHeader(title: l.t('Сипаттама', 'Описание')),
            SurfaceCard(
              child: Text(
                task.description.isEmpty
                    ? l.t('Қосымша сипаттама жоқ', 'Дополнительного описания нет')
                    : task.description,
                style: const TextStyle(fontSize: 14, height: 1.55),
              ),
            ),
            if (task.hasStatement) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: l.t('Есеп шарты', 'Условие задачи'),
                subtitle: l.t('Шешімді кодпен жаз', 'Решение напиши кодом'),
              ),
              SurfaceCard(
                child: Text(
                  task.statement,
                  style: const TextStyle(fontSize: 14.5, height: 1.55),
                ),
              ),
              if (task.examples.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (var i = 0; i < task.examples.length; i++) ...[
                  _ExampleCard(
                    l: l,
                    number: i + 1,
                    example: task.examples[i],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
            if (task.hasHint) ...[
              const SizedBox(height: 14),
              _HintCard(l: l, hint: task.hint),
            ],
            if (task.hasSolution) ...[
              const SizedBox(height: 14),
              _SolutionCard(l: l, solution: task.solution, opened: task.isDone),
            ],
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TopicDetailScreen(topicId: task.topic),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(l.t('Конспект', 'Конспект')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(topicId: task.topic),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: Text(l.t('Тест', 'Тест')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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


class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.l,
    required this.number,
    required this.example,
  });

  final L10n l;
  final int number;
  final TaskExample example;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t('$number-мысал', 'Пример $number'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 10),
            _IoRow(label: l.t('Кіріс', 'Ввод'), text: example.input),
            const SizedBox(height: 8),
            _IoRow(label: l.t('Шығыс', 'Вывод'), text: example.output),
          ],
        ),
      );
}

class _IoRow extends StatelessWidget {
  const _IoRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                fontFamily: 'Menlo',
              ),
            ),
          ),
        ],
      );
}

class _HintCard extends StatefulWidget {
  const _HintCard({required this.l, required this.hint});

  final L10n l;
  final String hint;

  @override
  State<_HintCard> createState() => _HintCardState();
}

class _HintCardState extends State<_HintCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.l;

    if (!_open) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _open = true),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: AppColors.warning,
        ),
        icon: const Icon(Icons.lightbulb_outline, size: 18),
        label: Text(l.t('Кеңесті ашу', 'Показать подсказку')),
      );
    }

    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 20, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.hint,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.l,
    required this.solution,
    required this.opened,
  });

  final L10n l;
  final String solution;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    if (!opened) {
      return SurfaceCard(
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.t(
                  'Талдау тапсырманы орындаған соң ашылады.',
                  'Разбор откроется после выполнения задания.',
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined,
                  size: 20, color: AppColors.success),
              const SizedBox(width: 10),
              Text(
                l.t('Шешімнің талдауы', 'Разбор решения'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            solution,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
