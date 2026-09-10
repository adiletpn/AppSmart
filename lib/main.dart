import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'firebase_options.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/schedule_repository.dart';
import 'data/repositories/task_repository.dart';
import 'state/app_state.dart';
import 'services/push_service.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final store = await LocalStore.create();
  await PushService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState(store)),
        ChangeNotifierProvider(
          create: (_) => AppState(
            auth: const AuthRepository(),
            tasksRepo: const TaskRepository(),
            scheduleRepo: const ScheduleRepository(),
            progressRepo: const ProgressRepository(),
            chatRepo: const ChatRepository(),
            notificationsRepo: const NotificationRepository(),
          )..bootstrap(),
        ),
      ],
      child: const SmartMentorApp(),
    ),
  );
}
