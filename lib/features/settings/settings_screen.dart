import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/lang_switch.dart';
import '../../widgets/primary_field.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final settings = context.watch<SettingsState>();
    final app = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Параметрлер', 'Настройки'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            SectionHeader(title: l.t('Тіл', 'Язык')),
            SurfaceCard(
              child: Row(
                children: [
                  const Icon(Icons.language, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l.t('Қосымша тілі', 'Язык приложения'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const LangSwitch(compact: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Тақырып', 'Тема')),
            SurfaceCard(
              child: Column(
                children: ThemeMode.values.map((mode) {
                  final selected = settings.themeMode == mode;
                  final label = switch (mode) {
                    ThemeMode.system => l.t('Жүйе бойынша', 'Как в системе'),
                    ThemeMode.light => l.t('Ашық', 'Светлая'),
                    ThemeMode.dark => l.t('Қараңғы', 'Тёмная'),
                  };
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => settings.setThemeMode(mode),
                    leading: Icon(
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
                    title: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: l.t('Хабарламалар', 'Уведомления'),
              subtitle: l.t('Еске салғыштарды басқару',
                  'Управление напоминаниями'),
            ),
            SurfaceCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.remindersEnabled,
                    onChanged: settings.setReminders,
                    title: Text(l.t('Оқу басталуын еске салу',
                        'Напоминать о начале занятия')),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.deadlineAlerts,
                    onChanged: settings.setDeadlineAlerts,
                    title: Text(l.t('Дедлайн туралы ескерту',
                        'Предупреждать о дедлайне')),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.weeklyReport,
                    onChanged: settings.setWeeklyReport,
                    title: Text(l.t('Апталық нәтиже', 'Итоги недели')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: l.t('AI ментор', 'AI-ментор'),
              subtitle: l.t('Gemini кілтін қоссаң, чат нақты AI-мен жауап береді',
                  'С ключом Gemini чат отвечает через настоящий AI'),
            ),
            const _ApiKeyCard(),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Деректер', 'Данные')),
            SurfaceCard(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l.t('Деректерді тазалау', 'Очистить данные')),
                    content: Text(
                      l.t(
                        'Тапсырмалар, жоспар, чат және тест нәтижелері өшіріледі.',
                        'Задания, план, чат и результаты тестов будут удалены.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l.t('Болдырмау', 'Отмена')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l.t('Өшіру', 'Удалить')),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await app.wipeData();
              },
              child: Row(
                children: [
                  const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.danger),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l.t('Барлық деректі тазалау', 'Очистить все данные'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: l.t('Қосымша туралы', 'О приложении')),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMART MENTOR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.t(
                      'Жатақханада тұратын оқушыларды информатика олимпиадасына дайындауға арналған AI ментор жүйесі.',
                      'AI-система подготовки к олимпиаде по информатике для учеников, живущих в интернате.',
                    ),
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.t('Нұсқа 1.0.0', 'Версия 1.0.0'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyCard extends StatefulWidget {
  const _ApiKeyCard();

  @override
  State<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends State<_ApiKeyCard> {
  late final TextEditingController _controller =
      TextEditingController(text: context.read<SettingsState>().apiKey);
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final settings = context.watch<SettingsState>();

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                settings.aiConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 20,
                color: settings.aiConnected
                    ? AppColors.success
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  settings.aiConnected
                      ? l.t('AI қосылған', 'AI подключён')
                      : l.t('Кіріктірілген алгоритм жұмыс істеп тұр',
                          'Работает встроенный алгоритм'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryField(
            controller: _controller,
            hint: 'AIza...',
            icon: Icons.key_outlined,
            obscure: _obscure,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.t(
              'Кілтті aistudio.google.com сайтынан тегін алуға болады.',
              'Ключ бесплатно берётся на aistudio.google.com.',
            ),
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await context
                        .read<SettingsState>()
                        .setApiKey(_controller.text);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.t('Сақталды', 'Сохранено')),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(l.t('Сақтау', 'Сохранить')),
                ),
              ),
              if (settings.aiConnected) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _controller.clear();
                      context.read<SettingsState>().setApiKey('');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: Text(l.t('Өшіру', 'Убрать')),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
