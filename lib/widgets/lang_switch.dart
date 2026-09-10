import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/l10n.dart';
import '../state/settings_state.dart';

class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppLang.values.map((lang) {
          final selected = settings.lang == lang;
          return GestureDetector(
            onTap: () => context.read<SettingsState>().setLang(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
                vertical: compact ? 6 : 9,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                compact ? lang.code.toUpperCase() : lang.title,
                style: TextStyle(
                  fontSize: compact ? 12 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
