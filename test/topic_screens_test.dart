import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_mentor/data/local/local_cache.dart';
import 'package:smart_mentor/data/local/local_store.dart';
import 'package:smart_mentor/data/repositories/auth_repository.dart';
import 'package:smart_mentor/data/repositories/chat_repository.dart';
import 'package:smart_mentor/data/repositories/notification_repository.dart';
import 'package:smart_mentor/data/repositories/progress_repository.dart';
import 'package:smart_mentor/data/repositories/schedule_repository.dart';
import 'package:smart_mentor/data/repositories/task_repository.dart';
import 'package:smart_mentor/features/topics/topic_detail_screen.dart';
import 'package:smart_mentor/features/topics/topics_screen.dart';
import 'package:smart_mentor/state/app_state.dart';
import 'package:smart_mentor/state/settings_state.dart';

Future<Widget> wrap(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final store = await LocalStore.create();

  return MultiProvider(
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
          cache: LocalCache(store),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('экран темы показывает конспект и кнопку теста', (tester) async {
    await tester.pumpWidget(
      await wrap(const TopicDetailScreen(topicId: 'loops')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Циклдер'), findsOneWidget);
    expect(find.text('Негізгі идея'), findsOneWidget);
    expect(find.text('Есте сақта'), findsOneWidget);

    // Қалған бөлігі экранға сыймайды — ListView оны айналдырғанда ғана құрады.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Жиі кететін қате'), findsOneWidget);
    expect(find.text('Осы тақырып бойынша тест'), findsOneWidget);
  });

  testWidgets('нетронутая тема помечена как не начатая', (tester) async {
    await tester.pumpWidget(
      await wrap(const TopicDetailScreen(topicId: 'loops')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Әлі басталмаған'), findsOneWidget);
  });

  testWidgets('неизвестная тема не роняет экран', (tester) async {
    await tester.pumpWidget(
      await wrap(const TopicDetailScreen(topicId: 'нет такой темы')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тақырып табылмады'), findsOneWidget);
  });

  testWidgets('каталог показывает все три уровня', (tester) async {
    await tester.pumpWidget(await wrap(const TopicsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Бастапқы деңгей'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Орта деңгей'), 400);
    expect(find.text('Орта деңгей'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Жоғары деңгей'), 400);
    expect(find.text('Жоғары деңгей'), findsOneWidget);
  });

  testWidgets('без данных у темы написано, что результатов нет',
      (tester) async {
    await tester.pumpWidget(await wrap(const TopicsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('әлі жоқ'), findsWidgets);
  });

  testWidgets('тап по теме открывает её экран', (tester) async {
    await tester.pumpWidget(await wrap(const TopicsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Циклдер').first);
    await tester.pumpAndSettle();

    expect(find.text('Негізгі идея'), findsOneWidget);
  });
}
