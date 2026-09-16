import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/models/quiz_attempt.dart';
import 'package:smart_mentor/data/models/quiz_question.dart';

QuizQuestion q(String topic, {int correct = 0}) => QuizQuestion(
      id: '$topic-$correct',
      topic: topic,
      prompt: 'вопрос по теме $topic',
      options: const ['а', 'б'],
      correctIndex: correct,
    );

QuizAttempt attempt(List<QuizQuestion> questions) => QuizAttempt.start(
      topic: 'Циклы',
      questions: questions,
      now: DateTime(2026, 9, 16),
    );

void main() {
  test('ответ засчитывается один раз', () {
    var a = attempt([q('Циклы')]);
    a = a.answer(0, 0);
    expect(a.score, 1);

    final again = a.answer(0, 1);
    expect(identical(again, a), isTrue);
    expect(a.score, 1);
  });

  test('ответ вне диапазона вариантов игнорируется', () {
    final a = attempt([q('Циклы')]);

    expect(identical(a.answer(0, 5), a), isTrue);
    expect(identical(a.answer(3, 0), a), isTrue);
  });

  test('после завершения ответы не принимаются', () {
    final a = attempt([q('Циклы'), q('Циклы')]).finish(DateTime(2026, 9, 16));

    expect(identical(a.answer(0, 0), a), isTrue);
    expect(a.score, 0);
  });

  test('результат разносится по темам вопросов', () {
    var a = attempt([
      q('Циклы', correct: 0),
      q('Циклы', correct: 1),
      q('Массивы и списки', correct: 0),
    ]);
    a = a.answer(0, 0);
    a = a.answer(1, 0);
    a = a.answer(2, 0);

    final byTopic = a.scoreByTopic;
    expect(byTopic['Циклы'], (score: 1, total: 2));
    expect(byTopic['Массивы и списки'], (score: 1, total: 1));
  });

  test('неотвеченные вопросы в разбивку не попадают', () {
    var a = attempt([q('Циклы'), q('Массивы и списки')]);
    a = a.answer(0, 0);

    expect(a.scoreByTopic.keys, ['Циклы']);
    expect(a.scoreByTopic['Циклы'], (score: 1, total: 1));
  });

  test('вопрос без темы относится к теме теста', () {
    var a = attempt([q('')]);
    a = a.answer(0, 0);

    expect(a.scoreByTopic.keys, ['Циклы']);
  });

  test('брошенный тест считает только отвеченное', () {
    var a = attempt([q('Циклы'), q('Циклы'), q('Циклы')]);
    a = a.answer(0, 0);
    a = a.answer(1, 1);
    final finished = a.finish(DateTime(2026, 9, 16));

    expect(finished.answeredCount, 2);
    expect(finished.score, 1);
    expect(finished.percent, closeTo(0.333, 0.01));
    expect(finished.scoreByTopic['Циклы'], (score: 1, total: 2));
  });
}
