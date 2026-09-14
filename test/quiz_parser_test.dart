import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/quiz_parser.dart';
import 'package:smart_mentor/data/ai/topic_catalog.dart';
import 'package:smart_mentor/data/models/quiz_question.dart';

void main() {
  final topic = TopicCatalog.byName('loops')!;

  List<QuizQuestion> parse(String? answer, {int count = 5}) =>
      QuizParser.parse(answer, topic: topic, isKz: false, count: count);

  test('разбирает обычный ответ модели', () {
    final questions = parse('''
[{"prompt":"Что делает break?","options":["Прерывает цикл","Пропускает шаг","Ничего","Ошибка"],"correct":0,"explanation":"break выходит из цикла."}]
''');

    expect(questions.length, 1);
    expect(questions.first.prompt, 'Что делает break?');
    expect(questions.first.correctOption, 'Прерывает цикл');
    expect(questions.first.explanation, 'break выходит из цикла.');
    expect(questions.first.topic, topic.ru);
  });

  test('markdown вокруг JSON не мешает разбору', () {
    final questions = parse('''
Вот тест:
```json
[{"prompt":"Сколько шагов?","options":["4","5"],"correct":1}]
```
''');

    expect(questions.length, 1);
    expect(questions.first.correctOption, '5');
  });

  test('индекс верного ответа принимается строкой и дробью', () {
    final asText = parse(
        '[{"prompt":"А","options":["раз","два"],"correct":"1"}]');
    final asDouble = parse(
        '[{"prompt":"Б","options":["раз","два"],"correct":1.0}]');

    expect(asText.first.correctOption, 'два');
    expect(asDouble.first.correctOption, 'два');
  });

  test('индекс за границами списка отбраковывает вопрос', () {
    expect(parse('[{"prompt":"А","options":["раз","два"],"correct":7}]'),
        isEmpty);
    expect(parse('[{"prompt":"А","options":["раз","два"],"correct":-1}]'),
        isEmpty);
    expect(parse('[{"prompt":"А","options":["раз","два"],"correct":"нет"}]'),
        isEmpty);
  });

  test('вопрос без вариантов или без текста отбрасывается', () {
    expect(parse('[{"prompt":"А","options":[],"correct":0}]'), isEmpty);
    expect(parse('[{"prompt":"А","options":["один"],"correct":0}]'), isEmpty);
    expect(parse('[{"prompt":"   ","options":["раз","два"],"correct":0}]'),
        isEmpty);
  });

  test('пустые варианты не считаются ответами', () {
    final questions =
        parse('[{"prompt":"А","options":["раз","","два",""],"correct":1}]');

    expect(questions.first.options, ['раз', 'два']);
    expect(questions.first.correctOption, 'два');
  });

  test('повторяющиеся вопросы убираются', () {
    final questions = parse('''
[{"prompt":"Что делает break?","options":["раз","два"],"correct":0},
 {"prompt":"что делает BREAK?","options":["раз","два"],"correct":1}]
''');

    expect(questions.length, 1);
  });

  test('лишние вопросы сверх запрошенного числа отрезаются', () {
    final questions = parse('''
[{"prompt":"А","options":["раз","два"],"correct":0},
 {"prompt":"Б","options":["раз","два"],"correct":0},
 {"prompt":"В","options":["раз","два"],"correct":0}]
''', count: 2);

    expect(questions.length, 2);
    expect(questions.last.prompt, 'Б');
  });

  test('битый ответ даёт пустой список', () {
    expect(parse(null), isEmpty);
    expect(parse(''), isEmpty);
    expect(parse('модель отказалась отвечать'), isEmpty);
    expect(parse('[{"prompt":"А", "options":'), isEmpty);
    expect(parse('{"prompt":"А"}'), isEmpty);
  });

  test('мусор внутри массива пропускается, а не роняет разбор', () {
    final questions = parse('''
["строка", 42, {"prompt":"А","options":["раз","два"],"correct":0}]
''');

    expect(questions.length, 1);
    expect(questions.first.prompt, 'А');
  });

  test('optionIndex проверяет границы списка', () {
    expect(QuizParser.optionIndex(0, 4), 0);
    expect(QuizParser.optionIndex(3, 4), 3);
    expect(QuizParser.optionIndex(4, 4), -1);
    expect(QuizParser.optionIndex(null, 4), -1);
    expect(QuizParser.optionIndex(' 2 ', 4), 2);
  });
}
