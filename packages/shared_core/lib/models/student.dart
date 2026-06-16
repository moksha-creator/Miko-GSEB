class Student {
  final String id;
  final int rollNo;
  final String name;
  final String avatarColor;
  final String avatarAsset;
  final Map<String, int> currentLevels;
  final List<FlaggedConcept> flaggedConcepts;
  final List<RecentSession> recentSessions;

  Student({
    required this.id,
    required this.rollNo,
    required this.name,
    required this.avatarColor,
    required this.avatarAsset,
    required this.currentLevels,
    required this.flaggedConcepts,
    required this.recentSessions,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      rollNo: json['roll_no'] as int,
      name: json['name'] as String,
      avatarColor: json['avatar_color'] as String,
      avatarAsset: json['avatar_asset'] as String? ?? '',
      currentLevels: Map<String, int>.from(json['current_levels'] as Map),
      flaggedConcepts: (json['flagged_concepts'] as List).map((e) => FlaggedConcept.fromJson(e as Map<String, dynamic>)).toList(),
      recentSessions: (json['recent_sessions'] as List).map((e) => RecentSession.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class FlaggedConcept {
  final String subject;
  final String concept;
  final String note;

  FlaggedConcept({required this.subject, required this.concept, required this.note});

  factory FlaggedConcept.fromJson(Map<String, dynamic> json) {
    return FlaggedConcept(
      subject: json['subject'] as String,
      concept: json['concept'] as String,
      note: json['note'] as String,
    );
  }
}

class RecentSession {
  final String date;
  final String subject;
  final String concept;
  final String outcome;

  RecentSession({required this.date, required this.subject, required this.concept, required this.outcome});

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    return RecentSession(
      date: json['date'] as String,
      subject: json['subject'] as String,
      concept: json['concept'] as String,
      outcome: json['outcome'] as String,
    );
  }
}
