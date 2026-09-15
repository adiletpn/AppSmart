import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/task_parser.dart';
import 'package:smart_mentor/data/models/study_task.dart';

void main() {
  final date = DateTime(2026, 9, 15, 14, 30);

  List<StudyTask> parse(String? answer, {int budget = 200}) =>
      TaskParser.parse(answer, userId: 'u1', date: date, budget: budget);

  test('разбирает задание с условием, примерами и разбором', () {
    final tasks = parse('''
[{"title":"Сумма чётных","description":"Разомнись","topic":"Циклы",
  "difficulty":"easy","minutes":25,
  "statement":"Дано n, выведи сумму чётных чисел от 1 до n.",
  "examples":[{"input":"10","output":"30"}],
  "hint":"Проверяй i % 2 == 0.","solution":"Один цикл, O(n)."}]
''');

    expect(tasks.length, 1);
    final task = tasks.first;
    expect(task.title, 'Сумма чётных');
    expect(task.topic, 'Циклы');
    expect(task.difficulty, TaskDifficulty.easy);
    expect(task.durationMinutes, 25);
    expect(task.hasStatement, isTrue);
    expect(task.examples.single.input, '10');
    expect(task.examples.single.output, '30');
    expect(task.hasHint, isTrue);
    expect(task.hasSolution, isTrue);
    expect(task.userId, 'u1');
  });

  test('день задания обрезается до начала суток', () {
    final task = parse('[{"title":"А","minutes":20}]').single;

    expect(task.date, DateTime(2026, 9, 15));
    expect(task.deadline.hour, 23);
    expect(task.deadline.minute, 59);
  });

  test('задание без условия остаётся валидным', () {
    final task = parse('[{"title":"Разбор теории","minutes":30}]').single;

    expect(task.hasStatement, isFalse);
    expect(task.examples, isEmpty);
    expect(task.hasHint, isFalse);
  });

  test('минуты принимаются строкой и дробью и зажимаются в границы', () {
    expect(parse('[{"title":"А","minutes":"45"}]').single.durationMinutes, 45);
    expect(parse('[{"title":"А","minutes":29.6}]').single.durationMinutes, 30);
    expect(parse('[{"title":"А","minutes":500}]').single.durationMinutes,
        TaskParser.maxMinutes);
    expect(parse('[{"title":"А","minutes":1}]').single.durationMinutes,
        TaskParser.minMinutes);
    expect(parse('[{"title":"А","minutes":"скоро"}]').single.durationMinutes, 30);
  });

  test('неполные примеры отбрасываются', () {
    final task = parse('''
[{"title":"А","minutes":20,"examples":[
  {"input":"5","output":""},
  {"input":"","output":"3"},
  {"input":"7","output":"9"},
  "мусор"]}]
''').single;

    expect(task.examples.length, 1);
    expect(task.examples.single.input, '7');
  });

  test('больше трёх примеров не берём', () {
    final task = parse('''
[{"title":"А","minutes":20,"examples":[
  {"input":"1","output":"1"},{"input":"2","output":"2"},
  {"input":"3","output":"3"},{"input":"4","output":"4"}]}]
''').single;

    expect(task.examples.length, 3);
  });

  test('бюджет времени не превышается', () {
    final tasks = parse('''
[{"title":"А","minutes":40},{"title":"Б","minutes":40},{"title":"В","minutes":40}]
''', budget: 90);

    expect(tasks.length, 2);
    expect(tasks.fold<int>(0, (sum, t) => sum + t.durationMinutes), 80);
  });

  test('первое задание берётся даже если оно длиннее бюджета', () {
    final tasks = parse('[{"title":"А","minutes":90}]', budget: 20);

    expect(tasks.length, 1);
  });

  test('задания без названия пропускаются', () {
    final tasks = parse('''
[{"title":"","minutes":20},{"minutes":20},{"title":"Б","minutes":20}]
''');

    expect(tasks.length, 1);
    expect(tasks.single.title, 'Б');
  });

  test('неизвестная сложность становится средней', () {
    expect(parse('[{"title":"А","difficulty":"insane"}]').single.difficulty,
        TaskDifficulty.medium);
  });

  test('битый ответ даёт пустой список', () {
    expect(parse(null), isEmpty);
    expect(parse('модель не ответила'), isEmpty);
    expect(parse('[{"title":"А"'), isEmpty);
    expect(parse('{"title":"А"}'), isEmpty);
  });

  test('условие переживает сохранение и чтение задания', () {
    final task = parse('''
[{"title":"А","minutes":20,"statement":"Условие",
  "examples":[{"input":"1","output":"2"}],"hint":"Подсказка","solution":"Разбор"}]
''').single;
    final restored = StudyTask.fromJson(task.toJson());

    expect(restored.statement, 'Условие');
    expect(restored.examples.single.output, '2');
    expect(restored.hint, 'Подсказка');
    expect(restored.solution, 'Разбор');
  });
}
