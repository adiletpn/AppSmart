import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/task_repository.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState(store)),
        ChangeNotifierProvider(
          create: (_) => AppState(
            store: store,
            auth: AuthRepository(store),
            tasksRepo: TaskRepository(store),
            scheduleRepo: ScheduleRepository(store),
            progressRepo: ProgressRepository(store),
            chatRepo: ChatRepository(store),
            notificationsRepo: NotificationRepository(store),
          )..bootstrap(),
        ),
      ],
      child: const SmartMentorApp(),
    ),
  );
}
