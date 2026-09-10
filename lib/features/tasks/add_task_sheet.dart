import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../../data/ai/topic_catalog.dart';
import '../../data/models/study_task.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_field.dart';
import '../../widgets/section_header.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  TaskDifficulty _difficulty = TaskDifficulty.medium;
  int _duration = 40;
  String? _topic;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final user = app.user;
    if (user == null || _title.text.trim().isEmpty) return;
    final day = TimeUtils.dayStart(DateTime.now());
    await app.addTask(
      StudyTask(
        id: const Uuid().v4(),
        userId: user.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        topic: _topic ?? '',
        difficulty: _difficulty,
        durationMinutes: _duration,
        date: day,
        deadline: day.add(const Duration(hours: 23, minutes: 59)),
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final topics = TopicCatalog.all.map((t) => t.name(l.isKz)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: l.t('Жаңа тапсырма', 'Новое задание')),
            PrimaryField(
              controller: _title,
              hint: l.t('Тапсырма атауы', 'Название задания'),
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 12),
            PrimaryField(
              controller: _description,
              hint: l.t('Сипаттама', 'Описание'),
              icon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _topic,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: l.t('Тақырып', 'Тема'),
                prefixIcon: const Icon(Icons.topic_outlined, size: 20),
              ),
              items: topics
                  .map((topic) =>
                      DropdownMenuItem(value: topic, child: Text(topic)))
                  .toList(),
              onChanged: (value) => setState(() => _topic = value),
            ),
            const SizedBox(height: 18),
            Text(
              l.t('Күрделілік', 'Сложность'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskDifficulty.values.map((value) {
                final selected = _difficulty == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l.difficulty(value)),
                    selected: selected,
                    onSelected: (_) => setState(() => _difficulty = value),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.t('Ұзақтығы', 'Длительность')),
                Text(
                  l.duration(_duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: _duration.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              onChanged: (value) => setState(() => _duration = value.round()),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: Text(l.t('Сақтау', 'Сохранить')),
            ),
          ],
        ),
      ),
    );
  }
}
