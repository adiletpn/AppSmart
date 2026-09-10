import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../core/time_utils.dart';
import '../../data/ai/free_time_engine.dart';
import '../../data/models/app_user.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/primary_field.dart';
import '../../widgets/section_header.dart';
import '../../widgets/time_picker_tile.dart';
import '../home/home_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.editing = false});

  final bool editing;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _controller = PageController();
  final _olympiad = TextEditingController();
  final _extraTitle = TextEditingController();

  int _step = 0;
  late AppUser _draft;
  bool _ready = false;
  String _extraStart = '18:00';
  String _extraEnd = '19:30';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final user = context.read<AppState>().user;
    if (user != null) {
      _draft = user;
      _olympiad.text = user.olympiad;
      _ready = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _olympiad.dispose();
    _extraTitle.dispose();
    super.dispose();
  }

  void _update(AppUser Function(AppUser) change) =>
      setState(() => _draft = change(_draft));

  Future<void> _next() async {
    if (_step < 2) {
      setState(() => _step++);
      _controller.animateToPage(
        _step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
      return;
    }
    final app = context.read<AppState>();
    final navigator = Navigator.of(context);
    final updated = _draft.copyWith(olympiad: _olympiad.text.trim());
    if (widget.editing) {
      await app.saveProfile(updated);
      navigator.pop();
      return;
    }
    await app.completeProfile(updated);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _back() {
    if (_step == 0) {
      if (widget.editing) Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _controller.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titles = [
      l.t('Оқу мақсатың', 'Твоя цель'),
      l.t('Күн тәртібі', 'Режим дня'),
      l.t('Дайындық уақыты', 'Время на подготовку'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(titles[_step]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: List.generate(3, (index) {
                  final active = index <= _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [_goalStep(l), _routineStep(l), _studyStep(l)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _step < 2
                      ? l.t('Келесі', 'Далее')
                      : l.t('Жоспарды құру', 'Построить план'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalStep(L10n l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        SectionHeader(
          title: l.t('Сынып', 'Класс'),
          subtitle: l.t('Тапсырмалар осыған қарай таңдалады',
              'Задания подбираются под класс'),
        ),
        Wrap(
          spacing: 10,
          children: [8, 9, 10, 11].map((grade) {
            final selected = _draft.grade == grade;
            return ChoiceChip(
              label: Text('$grade'),
              selected: selected,
              onSelected: (_) => _update((u) => u.copyWith(grade: grade)),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),
        PrimaryField(
          controller: _olympiad,
          label: l.t('Олимпиада атауы', 'Название олимпиады'),
          hint: l.t('Информатика олимпиадасы', 'Олимпиада по информатике'),
          icon: Icons.emoji_events_outlined,
        ),
        const SizedBox(height: 26),
        SectionHeader(
          title: l.t('Дайындық деңгейі', 'Уровень подготовки'),
          subtitle: l.t('AI тапсырма күрделілігін осыдан бастайды',
              'С этого уровня AI начнёт подбирать сложность'),
        ),
        ...PrepLevel.values.map((level) {
          final selected = _draft.level == level;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              onTap: () => _update((u) => u.copyWith(level: level)),
              border: selected ? AppColors.primary : null,
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.level(level),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.levelHint(level),
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
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _routineStep(L10n l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        SectionHeader(
          title: l.t('Мектеп сабақтары', 'Уроки в школе'),
          subtitle: l.t('Дүйсенбі — жұма', 'Понедельник — пятница'),
        ),
        TimePickerTile(
          label: l.t('Басталуы', 'Начало'),
          value: _draft.schoolStart,
          icon: Icons.school_outlined,
          onChanged: (value) => _update((u) => u.copyWith(schoolStart: value)),
        ),
        const SizedBox(height: 10),
        TimePickerTile(
          label: l.t('Аяқталуы', 'Окончание'),
          value: _draft.schoolEnd,
          icon: Icons.school_outlined,
          onChanged: (value) => _update((u) => u.copyWith(schoolEnd: value)),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: l.t('Ұйқы', 'Сон')),
        TimePickerTile(
          label: l.t('Ұйқыға жату', 'Отбой'),
          value: _draft.sleepStart,
          icon: Icons.bedtime_outlined,
          onChanged: (value) => _update((u) => u.copyWith(sleepStart: value)),
        ),
        const SizedBox(height: 10),
        TimePickerTile(
          label: l.t('Ояну', 'Подъём'),
          value: _draft.sleepEnd,
          icon: Icons.wb_sunny_outlined,
          onChanged: (value) => _update((u) => u.copyWith(sleepEnd: value)),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: l.t('Тамақтану', 'Приёмы пищи')),
        TimePickerTile(
          label: l.t('Таңғы ас', 'Завтрак'),
          value: _draft.breakfast,
          icon: Icons.free_breakfast_outlined,
          onChanged: (value) => _update((u) => u.copyWith(breakfast: value)),
        ),
        const SizedBox(height: 10),
        TimePickerTile(
          label: l.t('Түскі ас', 'Обед'),
          value: _draft.lunch,
          icon: Icons.lunch_dining_outlined,
          onChanged: (value) => _update((u) => u.copyWith(lunch: value)),
        ),
        const SizedBox(height: 10),
        TimePickerTile(
          label: l.t('Кешкі ас', 'Ужин'),
          value: _draft.dinner,
          icon: Icons.dinner_dining_outlined,
          onChanged: (value) => _update((u) => u.copyWith(dinner: value)),
        ),
      ],
    );
  }

  Widget _studyStep(L10n l) {
    final free = FreeTimeEngine.freeMinutes(_draft, DateTime.now(), l);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        SectionHeader(
          title: l.t('Қосымша сабақтар', 'Дополнительные занятия'),
          subtitle: l.t('Үйірме, репетитор, секция',
              'Кружок, репетитор, секция'),
        ),
        ..._draft.extraClasses.map(
          (extra) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${extra.title}  ·  ${extra.start}–${extra.end}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _update(
                      (u) => u.copyWith(
                        extraClasses: [...u.extraClasses]..remove(extra),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
        SurfaceCard(
          child: Column(
            children: [
              PrimaryField(
                controller: _extraTitle,
                hint: l.t('Мысалы: математика үйірмесі',
                    'Например: кружок по математике'),
                icon: Icons.add,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TimePickerTile(
                      label: l.t('Басы', 'С'),
                      value: _extraStart,
                      onChanged: (value) => setState(() => _extraStart = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TimePickerTile(
                      label: l.t('Соңы', 'До'),
                      value: _extraEnd,
                      onChanged: (value) => setState(() => _extraEnd = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  if (_extraTitle.text.trim().isEmpty) return;
                  _update(
                    (u) => u.copyWith(
                      extraClasses: [
                        ...u.extraClasses,
                        ExtraClass(
                          title: _extraTitle.text.trim(),
                          start: _extraStart,
                          end: _extraEnd,
                        ),
                      ],
                    ),
                  );
                  _extraTitle.clear();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l.t('Қосу', 'Добавить')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: l.t('Дайындыққа қолжетімді уақыт', 'Окно для подготовки'),
        ),
        Row(
          children: [
            Expanded(
              child: TimePickerTile(
                label: l.t('Басы', 'С'),
                value: _draft.freeFrom,
                onChanged: (value) => _update((u) => u.copyWith(freeFrom: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimePickerTile(
                label: l.t('Соңы', 'До'),
                value: _draft.freeTo,
                onChanged: (value) => _update((u) => u.copyWith(freeTo: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(
          title: l.t('Күніне дайындық', 'Занятий в день'),
          subtitle: l.t('AI осы шектен аспайды', 'AI не выйдет за этот предел'),
        ),
        SurfaceCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.t('Ұзақтығы', 'Длительность')),
                  Text(
                    l.duration(_draft.dailyStudyMinutes),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _draft.dailyStudyMinutes.toDouble(),
                min: 30,
                max: 300,
                divisions: 18,
                onChanged: (value) => _update(
                  (u) => u.copyWith(dailyStudyMinutes: value.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GradientCard(
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('Есептелген бос уақыт', 'Свободного времени'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.duration(free),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.t(
                        'Бүгін ${TimeUtils.fromMinutes(TimeUtils.toMinutes(_draft.freeFrom))} мен ${_draft.freeTo} аралығында',
                        'Сегодня между ${_draft.freeFrom} и ${_draft.freeTo}',
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
