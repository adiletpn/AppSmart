import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/models/quiz_attempt.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/pill.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final AppState _app;

  /// Жауап бергеннен кейін сұрақ экранда қалады: оқушы қайсысы дұрыс
  /// екенін көріп, өзі «Әрі қарай» дегенде ғана келесіге өтеді.
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _app.startQuiz(widget.topicId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _app.closeQuiz());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final attempt = app.quiz;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('Мини-тест', 'Мини-тест'))),
      body: SafeArea(
        child: app.quizLoading
            ? _Loading(l: l)
            : attempt == null
                ? _Unavailable(l: l)
                : _shown >= attempt.total
                    ? _Finished(l: l, attempt: attempt)
                    : _Question(
                        l: l,
                        attempt: attempt,
                        index: _shown,
                        onNext: () => setState(() => _shown++),
                      ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.l});

  final L10n l;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              l.t('Сұрақтар дайындалып жатыр…', 'Готовим вопросы…'),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.l});

  final L10n l;

  @override
  Widget build(BuildContext context) => Center(
        child: EmptyState(
          icon: Icons.quiz_outlined,
          title: l.t('Бұл тақырыпта тест жоқ', 'По этой теме теста нет'),
          subtitle: l.t(
            'Басқа тақырыпты таңдап көр немесе кейінірек қайта кір.',
            'Попробуй другую тему или зайди позже.',
          ),
          actionLabel: l.t('Артқа', 'Назад'),
          onAction: () => Navigator.of(context).pop(),
        ),
      );
}

class _Question extends StatelessWidget {
  const _Question({
    required this.l,
    required this.attempt,
    required this.index,
    required this.onNext,
  });

  final L10n l;
  final QuizAttempt attempt;
  final int index;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final question = attempt.questions[index];
    final chosen = attempt.answerAt(index);
    final revealed = chosen != QuizAttempt.noAnswer;
    final isLast = index == attempt.total - 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _Progress(l: l, attempt: attempt, index: index),
        const SizedBox(height: 16),
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.topic,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                question.prompt,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) ...[
          _Option(
            text: question.options[i],
            revealed: revealed,
            correct: question.isCorrect(i),
            chosen: chosen == i,
            onTap: revealed
                ? null
                : () => context.read<AppState>().answerQuiz(i),
          ),
          const SizedBox(height: 10),
        ],
        if (revealed) ...[
          const SizedBox(height: 8),
          SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  question.isCorrect(chosen)
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 20,
                  color: question.isCorrect(chosen)
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.explanation.isEmpty
                        ? l.t(
                            'Дұрыс жауап: ${question.correctOption}',
                            'Верный ответ: ${question.correctOption}',
                          )
                        : question.explanation,
                    style: const TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(
              isLast
                  ? l.t('Нәтижені көру', 'Посмотреть результат')
                  : l.t('Әрі қарай', 'Дальше'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.l,
    required this.attempt,
    required this.index,
  });

  final L10n l;
  final QuizAttempt attempt;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = attempt.answeredCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l.t(
                '${index + 1}-сұрақ, барлығы ${attempt.total}',
                'Вопрос ${index + 1} из ${attempt.total}',
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const Spacer(),
            if (done > 0)
              Text(
                l.t(
                  'Дұрыс: ${attempt.score}/$done',
                  'Верно: ${attempt.score} из $done',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: attempt.score == done
                      ? AppColors.success
                      : theme.textTheme.bodySmall?.color,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: attempt.total == 0 ? 0 : done / attempt.total,
            minHeight: 7,
            backgroundColor: theme.dividerColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.text,
    required this.revealed,
    required this.correct,
    required this.chosen,
    required this.onTap,
  });

  final String text;
  final bool revealed;
  final bool correct;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlight = revealed && (correct || chosen);
    final color = correct ? AppColors.success : AppColors.danger;

    return Material(
      color: highlight ? color.withValues(alpha: 0.12) : theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight ? color : theme.dividerColor,
              width: highlight ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (highlight) ...[
                const SizedBox(width: 10),
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  size: 20,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.l, required this.attempt});

  final L10n l;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${attempt.score} / ${attempt.answeredCount}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Pill(
                text: '${(attempt.percent * 100).round()}%',
                color: attempt.percent >= 0.7
                    ? AppColors.success
                    : AppColors.warning,
                filled: true,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(200, 50),
                ),
                child: Text(l.t('Дайын', 'Готово')),
              ),
            ],
          ),
        ),
      );
}
