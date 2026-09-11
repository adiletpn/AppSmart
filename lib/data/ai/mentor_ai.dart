import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/progress_stats.dart';
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

abstract class MentorAi {
  Future<DailyPlan> buildDay({
    required AppUser user,
    required DateTime date,
    required ProgressStats stats,
    required List<StudyTask> history,
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
