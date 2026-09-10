import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../../data/models/schedule_item.dart';
import '../../state/app_state.dart';
import '../../widgets/ai_busy_banner.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/primary_field.dart';
import '../../widgets/section_header.dart';
import '../../widgets/time_picker_tile.dart';
import 'week_overview.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selected = TimeUtils.dayStart(DateTime.now());

  Color _colorFor(SlotType type) => switch (type) {
        SlotType.study => AppColors.primary,
        SlotType.school => AppColors.purple,
        SlotType.sleep => AppColors.lightMuted,
        SlotType.meal => AppColors.warning,
        SlotType.extra => AppColors.accent,
        SlotType.free => AppColors.success,
      };

  IconData _iconFor(SlotType type) => switch (type) {
        SlotType.study => Icons.menu_book,
        SlotType.school => Icons.school,
        SlotType.sleep => Icons.bedtime,
        SlotType.meal => Icons.restaurant,
        SlotType.extra => Icons.groups,
        SlotType.free => Icons.bolt,
      };

  Future<void> _openSlotSheet({ScheduleItem? item}) async {
    final app = context.read<AppState>();
    final user = app.user;
    if (user == null) return;

    final titleController = TextEditingController(text: item?.title ?? '');
    var start = item?.startTime ?? '16:00';
    var end = item?.endTime ?? '17:00';
    var type = item?.type ?? SlotType.study;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l = sheetContext.l;
        return StatefulBuilder(
          builder: (_, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: item == null
                        ? l.t('Жоспарға қосу', 'Добавить в план')
                        : l.t('Уақытты өзгерту', 'Изменить слот'),
                  ),
                  PrimaryField(
                    controller: titleController,
                    hint: l.t('Атауы', 'Название'),
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TimePickerTile(
                          label: l.t('Басы', 'С'),
                          value: start,
                          onChanged: (value) =>
                              setSheetState(() => start = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TimePickerTile(
                          label: l.t('Соңы', 'До'),
                          value: end,
                          onChanged: (value) => setSheetState(() => end = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SlotType.values
                        .map(
                          (value) => ChoiceChip(
                            label: Text(l.slotType(value)),
                            selected: type == value,
                            onSelected: (_) =>
                                setSheetState(() => type = value),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      final slot = ScheduleItem(
                        id: item?.id ?? const Uuid().v4(),
                        userId: user.id,
                        date: _selected,
                        startTime: start,
                        endTime: end,
                        type: type,
                        title: titleController.text.trim(),
                        manual: true,
                      );
                      app.upsertScheduleItem(slot);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(l.t('Сақтау', 'Сохранить')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final items = app.scheduleFor(_selected);
    final free = app.freeMinutesFor(_selected);
    final tasks = app.tasksFor(_selected);
    final weekStart =
        _selected.subtract(Duration(days: _selected.weekday - 1));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Smart Schedule', 'Smart Schedule')),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selected,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now().add(const Duration(days: 180)),
              );
              if (picked != null) {
                setState(() => _selected = TimeUtils.dayStart(picked));
              }
            },
            icon: const Icon(Icons.calendar_month),
          ),
          IconButton(
            onPressed: () => _openSlotSheet(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (_, index) {
                  final day = weekStart.add(Duration(days: index));
                  final selected = TimeUtils.sameDay(day, _selected);
                  final today = TimeUtils.sameDay(day, DateTime.now());
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selected = TimeUtils.dayStart(day)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.cardGradient : null,
                        color: selected
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: today && !selected
                            ? Border.all(color: AppColors.primary, width: 1.4)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l.weekdays[day.weekday - 1],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            GradientCard(
              child: Row(
                children: [
                  const Icon(Icons.timelapse, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.longDate(_selected),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.t(
                            'Бос уақыт: ${l.duration(free)}',
                            'Свободно: ${l.duration(free)}',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.t(
                            '${tasks.length} тапсырма жоспарланған',
                            'Запланировано заданий: ${tasks.length}',
                          ),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            WeekOverview(
              anchor: _selected,
              onSelectDay: (day) => setState(() => _selected = day),
            ),
            const SizedBox(height: 20),
            const AiBusyBanner(),
            SectionHeader(
              title: l.t('Күндік таймлайн', 'Таймлайн дня'),
              actionLabel: l.t('AI қайта құрсын', 'Пересобрать'),
              onAction: () => app.generatePlan(_selected, force: true),
            ),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.calendar_today,
                title: l.t('Жоспар әлі жоқ', 'План ещё не построен'),
                subtitle: l.t(
                  'AI күн тәртібіңді талдап, бос уақытыңа тапсырма орналастырады.',
                  'AI разберёт режим дня и расставит задания в свободные окна.',
                ),
                actionLabel: l.t('Жоспар құру', 'Построить план'),
                onAction: () => app.generatePlan(_selected, force: true),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                    onTap: item.manual ? () => _openSlotSheet(item: item) : null,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                _colorFor(item.type).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconFor(item.type),
                            size: 20,
                            color: _colorFor(item.type),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.startTime} – ${item.endTime} · ${l.slotType(item.type)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.manual)
                          IconButton(
                            onPressed: () => app.deleteScheduleItem(item.id),
                            icon: const Icon(Icons.close, size: 18),
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
