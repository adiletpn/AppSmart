import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../core/l10n.dart';
import '../../data/reports/progress_report.dart';
import '../../state/app_state.dart';
import '../../widgets/gradient_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    final user = app.user;
    if (user == null) return const SizedBox.shrink();

    final report = ProgressReport.build(
      user: user,
      stats: app.stats,
      tasks: app.tasks,
      tests: app.tests,
      l: l,
      now: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('Дайындық есебі', 'Отчёт о подготовке')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  GradientCard(
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 30),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l.t(
                              'Есепті мұғалімге немесе ата-анаңа жіберуге болады.',
                              'Отчёт можно отправить учителю или родителям.',
                            ),
                            style: const TextStyle(fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: SelectableText(
                      report,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        fontFamily: 'Menlo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: report));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l.t('Көшірілді', 'Скопировано')),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l.t('Көшіру', 'Копировать')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: report,
                          subject: l.t(
                            'SMART MENTOR — дайындық есебі',
                            'SMART MENTOR — отчёт о подготовке',
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(l.t('Жіберу', 'Отправить')),
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
