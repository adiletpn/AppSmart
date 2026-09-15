import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/ai/question_bank.dart';
import '../../data/ai/topic_catalog.dart';
import '../../data/ai/topic_theory.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_header.dart';
import '../quiz/quiz_screen.dart';

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topicId, this.score});

  final String topicId;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final topic = TopicCatalog.byName(topicId);
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.t('Тақырып табылмады', 'Тема не найдена'))),
      );
    }

    final theory = TheoryBank.forTopic(topic.id, isKz: l.isKz);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Тақырып', 'Тема'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name(l.isKz),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _levelLabel(l, topic),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (score != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      l.t(
                        'Меңгеру деңгейі: ${(score! * 100).round()}%',
                        'Освоено на ${(score! * 100).round()}%',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (theory != null) ...[
              const SizedBox(height: 22),
              SectionHeader(title: l.t('Негізгі идея', 'Главная мысль')),
              SurfaceCard(
                child: Text(
                  theory.idea,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(title: l.t('Есте сақта', 'Запомни')),
              for (final point in theory.points) ...[
                _Point(text: point),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              SectionHeader(title: l.t('Жиі кететін қате', 'Частая ошибка')),
              SurfaceCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 20, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        theory.pitfall,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizScreen(topicId: topic.id),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.quiz_outlined, size: 19),
              label: Text(
                l.t('Осы тақырып бойынша тест', 'Пройти тест по теме'),
              ),
            ),
            if (!QuestionBank.hasTopic(topic.id)) ...[
              const SizedBox(height: 10),
              Text(
                l.t(
                  'Сұрақтарды AI құрастырады — интернет қажет.',
                  'Вопросы соберёт AI — понадобится интернет.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _levelLabel(L10n l, Topic topic) => switch (topic.level.name) {
        'beginner' => l.t('Бастапқы деңгей', 'Начальный уровень'),
        'middle' => l.t('Орта деңгей', 'Средний уровень'),
        _ => l.t('Жоғары деңгей', 'Продвинутый уровень'),
      };
}

class _Point extends StatelessWidget {
  const _Point({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      );
}
