import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/l10n.dart';
import '../state/app_state.dart';

class AiFallbackBanner extends StatelessWidget {
  const AiFallbackBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fellBack = context.select<AppState, bool>((state) => state.aiFellBack);
    if (!fellBack) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off, size: 19, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('AI-ға қосыла алмадым', 'Не удалось связаться с AI'),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l.t(
                      'Жоспар кіріктірілген алгоритммен құрылды. Интернетті және кілтті тексер.',
                      'План построен встроенным алгоритмом. Проверь интернет и ключ в настройках.',
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  if (onRetry != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextButton(
                        onPressed: onRetry,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(l.t('Қайталау', 'Повторить')),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: context.read<AppState>().dismissFallbackNotice,
              icon: const Icon(Icons.close, size: 17),
              visualDensity: VisualDensity.compact,
              tooltip: l.t('Жабу', 'Закрыть'),
            ),
          ],
        ),
      ),
    );
  }
}
