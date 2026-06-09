class SessionStudent {
  final String id;
  final String name;
  final String status;
  final String level;
  final int timeSpentSeconds;
  final String lastQuestion;

  SessionStudent({
    required this.id,
    required this.name,
    required this.status,
    required this.level,
    required this.timeSpentSeconds,
    required this.lastQuestion,
  });

  factory SessionStudent.fromJson(Map<String, dynamic> json) {
    return SessionStudent(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      level: json['level'] as String,
      timeSpentSeconds: json['time_spent_seconds'] as int,
      lastQuestion: json['last_question'] as String,
    );
  }
}

class TodaySession {
  final String date;
  final String subject;
  final String chapter;
  final int dayOfWeek;
  final int totalDays;
  final List<SessionStudent> students;

  TodaySession({
    required this.date,
    required this.subject,
    required this.chapter,
    required this.dayOfWeek,
    required this.totalDays,
    required this.students,
  });

  factory TodaySession.fromJson(Map<String, dynamic> json) {
    return TodaySession(
      date: json['date'] as String,
      subject: json['subject'] as String,
      chapter: json['chapter'] as String,
      dayOfWeek: json['day_of_week'] as int,
      totalDays: json['total_days'] as int,
      students: (json['students'] as List).map((e) => SessionStudent.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
