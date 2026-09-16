import 'quiz_question.dart';

class QuizAttempt {
  final String topic;
  final List<QuizQuestion> questions;
  final List<int> answers;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final bool fromAi;

  const QuizAttempt({
    required this.topic,
    required this.questions,
    required this.answers,
    required this.startedAt,
    this.finishedAt,
    this.fromAi = false,
  });

  /// Жауап берілмеген сұрақ осы мәнмен белгіленеді.
  static const noAnswer = -1;

  factory QuizAttempt.start({
    required String topic,
    required List<QuizQuestion> questions,
    required DateTime now,
    bool fromAi = false,
  }) =>
      QuizAttempt(
        topic: topic,
        questions: questions,
        answers: List.filled(questions.length, noAnswer),
        startedAt: now,
        fromAi: fromAi,
      );

  int get total => questions.length;

  bool get isEmpty => questions.isEmpty;

  bool get isFinished => finishedAt != null;

  int get answeredCount => answers.where((a) => a != noAnswer).length;

  bool get isComplete => total > 0 && answeredCount == total;

  int get currentIndex {
    final index = answers.indexOf(noAnswer);
    return index == -1 ? total : index;
  }

  QuizQuestion? get current =>
      currentIndex < total ? questions[currentIndex] : null;

  int answerAt(int index) =>
      index >= 0 && index < answers.length ? answers[index] : noAnswer;

  int get score {
    var correct = 0;
    for (var i = 0; i < total; i++) {
      if (answers[i] != noAnswer && questions[i].isCorrect(answers[i])) {
        correct++;
      }
    }
    return correct;
  }

  double get percent => total == 0 ? 0 : score / total;

  Duration get spent => (finishedAt ?? startedAt).difference(startedAt);

  /// Сұрақтар бірнеше тақырыптан құралуы мүмкін (өз тақырыбында сұрақ
  /// жетпесе, көршілерінен толықтырылады). Нәтиже сол тақырыптардың әрқайсысына
  /// бөлек жазылуы үшін осылай топтастырылады.
  Map<String, ({int score, int total})> get scoreByTopic {
    final result = <String, ({int score, int total})>{};
    for (var i = 0; i < total; i++) {
      if (answers[i] == noAnswer) continue;
      final key = questions[i].topic.isEmpty ? topic : questions[i].topic;
      final current = result[key] ?? (score: 0, total: 0);
      result[key] = (
        score: current.score + (questions[i].isCorrect(answers[i]) ? 1 : 0),
        total: current.total + 1,
      );
    }
    return result;
  }

  List<QuizQuestion> get mistakes => [
        for (var i = 0; i < total; i++)
          if (answers[i] != noAnswer && !questions[i].isCorrect(answers[i]))
            questions[i],
      ];

  QuizAttempt answer(int questionIndex, int option) {
    if (isFinished) return this;
    if (questionIndex < 0 || questionIndex >= total) return this;
    if (answers[questionIndex] != noAnswer) return this;
    if (!questions[questionIndex].isValid) return this;
    if (option < 0 || option >= questions[questionIndex].options.length) {
      return this;
    }

    final updated = [...answers];
    updated[questionIndex] = option;
    return copyWith(answers: updated);
  }

  QuizAttempt finish(DateTime now) =>
      isFinished ? this : copyWith(finishedAt: now);

  QuizAttempt copyWith({
    List<int>? answers,
    DateTime? finishedAt,
  }) =>
      QuizAttempt(
        topic: topic,
        questions: questions,
        answers: answers ?? this.answers,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        fromAi: fromAi,
      );
}
