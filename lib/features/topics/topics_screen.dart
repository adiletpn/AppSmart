import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/ai/topic_catalog.dart';
import '../../data/models/app_user.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_header.dart';
import 'topic_detail_screen.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final scores = app.stats.topicScores;
    final level = app.user?.level ?? PrepLevel.beginner;
    final available = TopicCatalog.forLevel(level).map((t) => t.id).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Тақырыптар', 'Темы'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GradientCard(
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l.t(
                        'Әр тақырыпта қысқа конспект пен тест бар. '
                            'Деңгейіңнен жоғарысы да ашық — алға оқуға болады.',
                        'В каждой теме есть конспект и тест. Темы выше твоего '
                            'уровня тоже открыты — можно читать наперёд.',
                      ),
                      style: const TextStyle(fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            for (final group in PrepLevel.values) ...[
              const SizedBox(height: 22),
              SectionHeader(
                title: _levelTitle(l, group),
                subtitle: _levelSubtitle(l, group, available, scores),
              ),
              for (final topic in TopicCatalog.focusFor(group)) ...[
                _TopicRow(
                  l: l,
                  topic: topic,
                  score: scores[topic.kk] ?? scores[topic.ru],
                  beyondLevel: !available.contains(topic.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _levelTitle(L10n l, PrepLevel level) => switch (level) {
        PrepLevel.beginner => l.t('Бастапқы деңгей', 'Начальный уровень'),
        PrepLevel.middle => l.t('Орта деңгей', 'Средний уровень'),
        PrepLevel.advanced => l.t('Жоғары деңгей', 'Продвинутый уровень'),
      };

  String _levelSubtitle(
    L10n l,
    PrepLevel level,
    Set<String> available,
    Map<String, double> scores,
  ) {
    final topics = TopicCatalog.focusFor(level);
    final studied = topics
        .where((t) => scores.containsKey(t.kk) || scores.containsKey(t.ru))
        .length;

    if (!available.contains(topics.first.id)) {
      return l.t('Деңгейіңнен жоғары', 'Выше твоего уровня');
    }
    return l.t(
      '${topics.length} тақырыптың $studied-і басталған',
      'Начато $studied из ${topics.length}',
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.l,
    required this.topic,
    required this.score,
    required this.beyondLevel,
  });

  final L10n l;
  final Topic topic;
  final double? score;
  final bool beyondLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = score;
    final color = value == null
        ? theme.dividerColor
        : value >= 0.7
            ? AppColors.success
            : AppColors.warning;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TopicDetailScreen(topicId: topic.id, score: score),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.name(l.isKz),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: beyondLevel
                            ? theme.textTheme.bodySmall?.color
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    value == null
                        ? l.t('әлі жоқ', 'нет данных')
                        : '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: value == null
                          ? theme.textTheme.bodySmall?.color
                          : color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right,
                      size: 18, color: theme.textTheme.bodySmall?.color),
                ],
              ),
              if (value != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
