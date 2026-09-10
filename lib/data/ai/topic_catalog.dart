import '../models/app_user.dart';

class Topic {
  final String id;
  final String kk;
  final String ru;
  final PrepLevel level;

  const Topic(this.id, this.kk, this.ru, this.level);

  String name(bool isKz) => isKz ? kk : ru;
}

class TopicCatalog {
  static const all = <Topic>[
    Topic('algo_basics', 'Алгоритм негіздері', 'Основы алгоритмов',
        PrepLevel.beginner),
    Topic('python_syntax', 'Python синтаксисі', 'Синтаксис Python',
        PrepLevel.beginner),
    Topic('conditions', 'Шартты операторлар', 'Условные операторы',
        PrepLevel.beginner),
    Topic('loops', 'Циклдер', 'Циклы', PrepLevel.beginner),
    Topic('arrays', 'Массивтер мен тізімдер', 'Массивы и списки',
        PrepLevel.beginner),
    Topic('strings', 'Жолдармен жұмыс', 'Работа со строками',
        PrepLevel.beginner),
    Topic('functions', 'Функциялар', 'Функции', PrepLevel.beginner),
    Topic('sorting', 'Сұрыптау алгоритмдері', 'Алгоритмы сортировки',
        PrepLevel.beginner),
    Topic('search', 'Іздеу алгоритмдері', 'Алгоритмы поиска',
        PrepLevel.beginner),
    Topic('complexity', 'Күрделілік және O-белгілеу', 'Сложность и O-нотация',
        PrepLevel.middle),
    Topic('binary_search', 'Екілік іздеу', 'Бинарный поиск', PrepLevel.middle),
    Topic('prefix_sums', 'Префикс қосындылар', 'Префиксные суммы',
        PrepLevel.middle),
    Topic('two_pointers', 'Екі көрсеткіш әдісі', 'Метод двух указателей',
        PrepLevel.middle),
    Topic('stack_queue', 'Стек және кезек', 'Стек и очередь', PrepLevel.middle),
    Topic('recursion', 'Рекурсия', 'Рекурсия', PrepLevel.middle),
    Topic('combinatorics', 'Комбинаторика', 'Комбинаторика', PrepLevel.middle),
    Topic('number_theory', 'Сандар теориясы', 'Теория чисел', PrepLevel.middle),
    Topic('graphs_basic', 'Графтар: BFS және DFS', 'Графы: BFS и DFS',
        PrepLevel.middle),
    Topic('sets_maps', 'Жиындар мен сөздіктер', 'Множества и словари',
        PrepLevel.middle),
    Topic('greedy', 'Ашкөз алгоритмдер', 'Жадные алгоритмы', PrepLevel.middle),
    Topic('dp', 'Динамикалық программалау', 'Динамическое программирование',
        PrepLevel.advanced),
    Topic('dijkstra', 'Дейкстра алгоритмі', 'Алгоритм Дейкстры',
        PrepLevel.advanced),
    Topic('trees', 'Ағаштар', 'Деревья', PrepLevel.advanced),
    Topic('dsu', 'DSU құрылымы', 'Система непересекающихся множеств',
        PrepLevel.advanced),
    Topic('segment_tree', 'Segment Tree', 'Дерево отрезков',
        PrepLevel.advanced),
    Topic('geometry', 'Есептеу геометриясы', 'Вычислительная геометрия',
        PrepLevel.advanced),
    Topic('strings_algo', 'Жол алгоритмдері (KMP)', 'Строковые алгоритмы (KMP)',
        PrepLevel.advanced),
    Topic('bitmask', 'Биттік маскалар', 'Битовые маски', PrepLevel.advanced),
  ];

  static List<Topic> forLevel(PrepLevel level) {
    final order = PrepLevel.values.indexOf(level);
    return all
        .where((t) => PrepLevel.values.indexOf(t.level) <= order)
        .toList();
  }

  static List<Topic> focusFor(PrepLevel level) =>
      all.where((t) => t.level == level).toList();

  static Topic? byName(String name) {
    for (final topic in all) {
      if (topic.kk == name || topic.ru == name || topic.id == name) return topic;
    }
    return null;
  }
}
