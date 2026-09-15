import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/l10n.dart';
import '../state/app_state.dart';

/// Байланыс жоқта немесе өзгерістер серверге әлі жетпегенде көрінеді.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    if (!app.showSyncBanner) return const SizedBox.shrink();

    final offline = app.offline;
    final color = offline ? AppColors.warning : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.cloud_sync_outlined,
              size: 19,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offline
                        ? l.t('Желісіз режим', 'Режим без сети')
                        : l.t('Сақталуда', 'Сохраняем'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    offline
                        ? l.t(
                            'Құрылғыдағы көшірмемен жұмыс істеп тұрсың. '
                                'Барлық өзгеріс сақталады да, байланыс қалпына '
                                'келгенде серверге жіберіледі.',
                            'Работаешь с копией на устройстве. Все изменения '
                                'сохраняются и уйдут на сервер, когда появится связь.',
                          )
                        : l.t(
                            'Соңғы өзгерістер серверге жіберіліп жатыр.',
                            'Последние изменения отправляются на сервер.',
                          ),
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            if (offline) ...[
              const SizedBox(width: 8),
              app.syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : IconButton(
                      onPressed: app.retrySync,
                      tooltip: l.t('Қайталау', 'Повторить'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.refresh, size: 20, color: color),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
