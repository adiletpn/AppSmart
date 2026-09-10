enum PrepLevel { beginner, middle, advanced }

class ExtraClass {
  final String title;
  final String start;
  final String end;
  final List<int> weekdays;

  const ExtraClass({
    required this.title,
    required this.start,
    required this.end,
    this.weekdays = const [1, 2, 3, 4, 5],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'start': start,
        'end': end,
        'weekdays': weekdays,
      };

  factory ExtraClass.fromJson(Map<String, dynamic> json) => ExtraClass(
        title: json['title'] as String? ?? '',
        start: json['start'] as String? ?? '18:00',
        end: json['end'] as String? ?? '19:00',
        weekdays: (json['weekdays'] as List?)?.map((e) => e as int).toList() ??
            const [1, 2, 3, 4, 5],
      );
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final int grade;
  final String subject;
  final String olympiad;
  final PrepLevel level;
  final String schoolStart;
  final String schoolEnd;
  final String sleepStart;
  final String sleepEnd;
  final String breakfast;
  final String lunch;
  final String dinner;
  final List<ExtraClass> extraClasses;
  final int dailyStudyMinutes;
  final String freeFrom;
  final String freeTo;
  final bool profileCompleted;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.grade = 8,
    this.subject = 'Информатика',
    this.olympiad = 'Информатика олимпиадасы',
    this.level = PrepLevel.beginner,
    this.schoolStart = '08:00',
    this.schoolEnd = '14:00',
    this.sleepStart = '23:00',
    this.sleepEnd = '07:00',
    this.breakfast = '07:30',
    this.lunch = '13:00',
    this.dinner = '19:00',
    this.extraClasses = const [],
    this.dailyStudyMinutes = 120,
    this.freeFrom = '15:00',
    this.freeTo = '22:00',
    this.profileCompleted = false,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    int? grade,
    String? subject,
    String? olympiad,
    PrepLevel? level,
    String? schoolStart,
    String? schoolEnd,
    String? sleepStart,
    String? sleepEnd,
    String? breakfast,
    String? lunch,
    String? dinner,
    List<ExtraClass>? extraClasses,
    int? dailyStudyMinutes,
    String? freeFrom,
    String? freeTo,
    bool? profileCompleted,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        grade: grade ?? this.grade,
        subject: subject ?? this.subject,
        olympiad: olympiad ?? this.olympiad,
        level: level ?? this.level,
        schoolStart: schoolStart ?? this.schoolStart,
        schoolEnd: schoolEnd ?? this.schoolEnd,
        sleepStart: sleepStart ?? this.sleepStart,
        sleepEnd: sleepEnd ?? this.sleepEnd,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        extraClasses: extraClasses ?? this.extraClasses,
        dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
        freeFrom: freeFrom ?? this.freeFrom,
        freeTo: freeTo ?? this.freeTo,
        profileCompleted: profileCompleted ?? this.profileCompleted,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'grade': grade,
        'subject': subject,
        'olympiad': olympiad,
        'level': level.name,
        'schoolStart': schoolStart,
        'schoolEnd': schoolEnd,
        'sleepStart': sleepStart,
        'sleepEnd': sleepEnd,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'extraClasses': extraClasses.map((e) => e.toJson()).toList(),
        'dailyStudyMinutes': dailyStudyMinutes,
        'freeFrom': freeFrom,
        'freeTo': freeTo,
        'profileCompleted': profileCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        grade: json['grade'] as int? ?? 8,
        subject: json['subject'] as String? ?? 'Информатика',
        olympiad: json['olympiad'] as String? ?? 'Информатика олимпиадасы',
        level: PrepLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => PrepLevel.beginner,
        ),
        schoolStart: json['schoolStart'] as String? ?? '08:00',
        schoolEnd: json['schoolEnd'] as String? ?? '14:00',
        sleepStart: json['sleepStart'] as String? ?? '23:00',
        sleepEnd: json['sleepEnd'] as String? ?? '07:00',
        breakfast: json['breakfast'] as String? ?? '07:30',
        lunch: json['lunch'] as String? ?? '13:00',
        dinner: json['dinner'] as String? ?? '19:00',
        extraClasses: (json['extraClasses'] as List?)
                ?.map((e) => ExtraClass.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        dailyStudyMinutes: json['dailyStudyMinutes'] as int? ?? 120,
        freeFrom: json['freeFrom'] as String? ?? '15:00',
        freeTo: json['freeTo'] as String? ?? '22:00',
        profileCompleted: json['profileCompleted'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
