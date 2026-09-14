import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/question_bank.dart';
import 'package:smart_mentor/data/ai/topic_catalog.dart';
import 'package:smart_mentor/data/models/app_user.dart';

void main() {
  test('вопросы выдаются только по запрошенной теме', () {
    final questions = QuestionBank.forTopic('loops', isKz: false);

    expect(questions, isNotEmpty);
    for (final question in questions) {
      expect(question.topic, TopicCatalog.byName('loops')!.ru);
    }
  });

  test('неизвестная тема даёт пустой список', () {
    expect(QuestionBank.forTopic('нет такой темы', isKz: false), isEmpty);
  });

  test('каждый вопрос банка проходит проверку', () {
    for (final topic in QuestionBank.topics) {
      for (final question in QuestionBank.forTopic(topic, isKz: false)) {
        expect(question.isValid, isTrue, reason: '$topic: ${question.prompt}');
      }
    }
  });

  test('после перемешивания правильный ответ остаётся верным', () {
    for (var seed = 0; seed < 20; seed++) {
      final questions = QuestionBank.forTopic('arrays', isKz: false, seed: seed);
      for (final question in questions) {
        expect(question.isCorrect(question.correctIndex), isTrue);
        expect(question.options[question.correctIndex], question.correctOption);
      }
    }
  });

  test('в списке индекса первого элемента верный ответ — ноль', () {
    final question = QuestionBank.forTopic('arrays', isKz: false, seed: 3)
        .firstWhere((q) => q.prompt.contains('индекс'));

    expect(question.correctOption, '0');
  });

  test('одинаковый seed даёт одинаковый набор вопросов', () {
    final first = QuestionBank.forTopic('sorting', isKz: false, seed: 7);
    final second = QuestionBank.forTopic('sorting', isKz: false, seed: 7);

    expect(
      first.map((q) => q.prompt).toList(),
      second.map((q) => q.prompt).toList(),
    );
    expect(first.first.options, second.first.options);
  });

  test('язык меняет формулировку вопроса и тему', () {
    final ru = QuestionBank.forTopic('recursion', isKz: false, seed: 1).first;
    final kk = QuestionBank.forTopic('recursion', isKz: true, seed: 1).first;

    expect(ru.prompt, isNot(kk.prompt));
    expect(ru.topic, 'Рекурсия');
    expect(kk.topic, 'Рекурсия');
  });

  test('число вопросов не превышает запрошенное', () {
    final questions = QuestionBank.forTopic('strings', isKz: false, count: 1);

    expect(questions.length, 1);
  });

  test('добор дополняет тест до нужного числа вопросов', () {
    final own = QuestionBank.forTopic('loops', isKz: false, count: 5);
    final test = QuestionBank.forTest('loops', isKz: false, count: 5);

    expect(own.length, lessThan(5));
    expect(test.length, 5);
  });

  test('свои вопросы идут перед добором', () {
    final test = QuestionBank.forTest('loops', isKz: false, count: 5);
    final own = TopicCatalog.byName('loops')!.ru;

    expect(test.first.topic, own);
    expect(test.where((q) => q.topic == own).length, 2);
  });

  test('добор берёт темы только своего уровня', () {
    final test = QuestionBank.forTest('loops', isKz: false, count: 5);

    for (final question in test) {
      final topic = TopicCatalog.all.firstWhere((t) => t.ru == question.topic);
      expect(topic.level, PrepLevel.beginner);
    }
  });

  test('в наборе нет повторяющихся вопросов', () {
    final test = QuestionBank.forTest('arrays', isKz: false, count: 5);
    final prompts = test.map((q) => q.prompt).toSet();

    expect(prompts.length, test.length);
  });

  test('добор не нужен, когда вопросов хватает', () {
    final test = QuestionBank.forTest('loops', isKz: false, count: 2);

    expect(test.length, 2);
    expect(test.every((q) => q.topic == TopicCatalog.byName('loops')!.ru),
        isTrue);
  });

  test('тема вне банка не добирается', () {
    expect(QuestionBank.forTest('dp', isKz: false, count: 5), isEmpty);
    expect(QuestionBank.forTest('нет такой темы', isKz: false), isEmpty);
  });

  test('добор сохраняет верный ответ каждого вопроса', () {
    for (var seed = 0; seed < 10; seed++) {
      for (final question
          in QuestionBank.forTest('strings', isKz: false, seed: seed)) {
        expect(question.isValid, isTrue);
        expect(question.options[question.correctIndex], question.correctOption);
      }
    }
  });
}
