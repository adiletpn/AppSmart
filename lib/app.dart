import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/l10n.dart';
import 'data/ai/gemini_mentor_ai.dart';
import 'data/ai/local_mentor_ai.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';

class SmartMentorApp extends StatelessWidget {
  const SmartMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    context.read<AppState>().configure(
          ai: settings.aiConnected
              ? GeminiMentorAi(apiKey: settings.apiKey)
              : const LocalMentorAi(),
          isKz: settings.lang == AppLang.kk,
        );

    return MaterialApp(
      title: 'SMART MENTOR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
