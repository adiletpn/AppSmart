import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/progress_stats.dart';
import '../models/quiz_question.dart';
import '../models/schedule_item.dart';
import '../models/study_task.dart';

enum PlanSource { ai, local }

class DailyPlan {
  final List<StudyTask> tasks;
  final List<ScheduleItem> schedule;
  final String advice;
  final int freeMinutes;
  final int studyMinutes;
  final PlanSource source;

  const DailyPlan({
    required this.tasks,
    required this.schedule,
    required this.advice,
    required this.freeMinutes,
    required this.studyMinutes,
    this.source = PlanSource.local,
  });
}

enum QuizSource { ai, bank }

class QuizSet {
  final String topic;
  final List<QuizQuestion> questions;
  final QuizSource source;

  const QuizSet({
    required this.topic,
    required this.questions,
    this.source = QuizSource.bank,
  });

  static const empty = QuizSet(topic: '', questions: []);

  bool get isEmpty => questions.isEmpty;

  int get length => questions.length;
}

abstract class MentorAi {
  Future<DailyPlan> buildDay({
    required AppUser user,
    required DateTime date,
    required ProgressStats stats,
    required List<StudyTask> history,
    required bool isKz,
  });

  Future<QuizSet> buildQuiz({
    required String topicId,
    required int count,
    required bool isKz,
  });

  Future<String> advice({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> today,
    required bool isKz,
  });

  Future<String> reply({
    required AppUser user,
    required ProgressStats stats,
    required List<StudyTask> today,
    required List<ChatMessage> history,
    required String message,
    required bool isKz,
  });
}
