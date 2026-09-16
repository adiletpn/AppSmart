import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mentor/data/ai/question_bank.dart';
import 'package:smart_mentor/data/ai/task_content_bank.dart';
import 'package:smart_mentor/data/ai/topic_catalog.dart';
import 'package:smart_mentor/data/ai/topic_theory.dart';

void main() {
  test('у каждой темы каталога есть задача, вопросы и конспект', () {
    for (final topic in TopicCatalog.all) {
      expect(TaskContentBank.hasTopic(topic.id), isTrue,
          reason: 'нет условия задачи: ${topic.id}');
      expect(QuestionBank.hasTopic(topic.id), isTrue,
          reason: 'нет вопросов: ${topic.id}');
      expect(TheoryBank.hasTopic(topic.id), isTrue,
          reason: 'нет конспекта: ${topic.id}');
    }
  });

  test('у каждой задачи есть примеры, подсказка и разбор на двух языках', () {
    for (final topic in TopicCatalog.all) {
      for (final isKz in [true, false]) {
        final content = TaskContentBank.forTopic(topic.id, isKz: isKz)!;
        expect(content.statement.trim(), isNotEmpty, reason: topic.id);
        expect(content.examples.length, greaterThanOrEqualTo(2),
            reason: topic.id);
        expect(content.hint.trim(), isNotEmpty, reason: topic.id);
        expect(content.solution.trim(), isNotEmpty, reason: topic.id);
      }
    }
  });

  test('примеры заполнены с обеих сторон', () {
    for (final topic in TopicCatalog.all) {
      for (final example
          in TaskContentBank.forTopic(topic.id, isKz: false)!.examples) {
        expect(example.input.trim(), isNotEmpty, reason: topic.id);
        expect(example.output.trim(), isNotEmpty, reason: topic.id);
      }
    }
  });

  test('в примерах не осталось двуязычных заглушек', () {
    for (final topic in TopicCatalog.all) {
      for (final example
          in TaskContentBank.forTopic(topic.id, isKz: false)!.examples) {
        expect(example.output, isNot(contains(' / ')), reason: topic.id);
      }
    }
  });

  test('конспект каждой темы содержит идею, пункты и ошибку', () {
    for (final topic in TopicCatalog.all) {
      for (final isKz in [true, false]) {
        final theory = TheoryBank.forTopic(topic.id, isKz: isKz)!;
        expect(theory.idea.trim(), isNotEmpty, reason: topic.id);
        expect(theory.points.length, greaterThanOrEqualTo(3), reason: topic.id);
        expect(theory.pitfall.trim(), isNotEmpty, reason: topic.id);
      }
    }
  });
}
