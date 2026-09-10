import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../state/settings_state.dart';
import '../../widgets/lang_switch.dart';
import '../auth/login_screen.dart';

class _Slide {
  final IconData icon;
  final String titleKz;
  final String titleRu;
  final String bodyKz;
  final String bodyRu;

  const _Slide(this.icon, this.titleKz, this.titleRu, this.bodyKz, this.bodyRu);
}

const _slides = <_Slide>[
  _Slide(
    Icons.schedule,
    'Күн тәртібіңді талдаймыз',
    'Разберём твой режим дня',
    'Сабақ, ұйқы және тамақтану уақытын енгізесің — жүйе бос уақытыңды өзі есептейді.',
    'Ты вводишь уроки, сон и приёмы пищи — система сама посчитает свободное время.',
  ),
  _Slide(
    Icons.auto_awesome,
    'AI жеке жоспар құрады',
    'AI составит личный план',
    'Олимпиада мақсатың мен деңгейіңе қарай күнделікті оқу жоспары жасалады.',
    'План занятий строится под твою цель и текущий уровень подготовки.',
  ),
  _Slide(
    Icons.task_alt,
    'Күнделікті тапсырмалар',
    'Ежедневные задания',
    'Әр күні нақты тапсырма аласың: тақырып, күрделілік және дедлайн көрсетіледі.',
    'Каждый день — конкретное задание: тема, сложность и дедлайн.',
  ),
  _Slide(
    Icons.insights,
    'Прогресті бақылаймыз',
    'Отследим прогресс',
    'Әлсіз тақырыптарың анықталып, жоспар нәтижеңе қарай бейімделеді.',
    'Слабые темы определяются автоматически, план адаптируется под результат.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsState>().setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final last = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  const LangSwitch(compact: true),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(l.t('Өткізіп жіберу', 'Пропустить')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon,
                              size: 68, color: Colors.white),
                        ),
                        const SizedBox(height: 42),
                        Text(
                          l.t(slide.titleKz, slide.titleRu),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.t(slide.bodyKz, slide.bodyRu),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final active = index == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: FilledButton(
                onPressed: _next,
                child: Text(last ? l.t('Бастау', 'Начать') : l.t('Келесі', 'Далее')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
