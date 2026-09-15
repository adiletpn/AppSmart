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
                : attempt.isFinished
                    ? _Finished(l: l, attempt: attempt)
                    : _Question(l: l, attempt: attempt),
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
  const _Question({required this.l, required this.attempt});

  final L10n l;
  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final question = attempt.current!;
    final number = attempt.currentIndex + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$number / ${attempt.total}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    question.topic,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
            onTap: () => context.read<AppState>().answerQuiz(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.3),
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
