enum RosterStatus { waiting, inProgress, completed, absent }

extension RosterStatusExtension on RosterStatus {
  String get name {
    switch (this) {
      case RosterStatus.waiting: return 'waiting';
      case RosterStatus.inProgress: return 'in_progress';
      case RosterStatus.completed: return 'completed';
      case RosterStatus.absent: return 'absent';
    }
  }

  static RosterStatus fromString(String val) {
    switch (val) {
      case 'in_progress': return RosterStatus.inProgress;
      case 'completed': return RosterStatus.completed;
      case 'absent': return RosterStatus.absent;
      default: return RosterStatus.waiting;
    }
  }
}

class RosterEntry {
  final String studentId;
  final String studentName;
  final int rollNumber;
  final String subject;
  final int week;
  final String day;
  final RosterStatus status;
  final String lastQuestion;
  final int timeSpentSeconds;
  final String level;

  RosterEntry({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.subject,
    required this.week,
    required this.day,
    this.status = RosterStatus.waiting,
    this.lastQuestion = '',
    this.timeSpentSeconds = 0,
    this.level = 'L1',
  });

  RosterEntry copyWith({
    RosterStatus? status,
    String? lastQuestion,
    int? timeSpentSeconds,
    String? level,
  }) {
    return RosterEntry(
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      subject: subject,
      week: week,
      day: day,
      status: status ?? this.status,
      lastQuestion: lastQuestion ?? this.lastQuestion,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      level: level ?? this.level,
    );
  }

  factory RosterEntry.fromJson(Map<String, dynamic> json) {
    return RosterEntry(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      rollNumber: json['rollNumber'] ?? 0,
      subject: json['subject'] ?? '',
      week: json['week'] ?? 1,
      day: json['day'] ?? 'Monday',
      status: RosterStatusExtension.fromString(json['status'] ?? 'waiting'),
      lastQuestion: json['lastQuestion'] ?? '',
      timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      level: json['level'] ?? 'L1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'subject': subject,
      'week': week,
      'day': day,
      'status': status.name,
      'lastQuestion': lastQuestion,
      'timeSpentSeconds': timeSpentSeconds,
      'level': level,
    };
  }
}

class WeekPlan {
  final int weekNumber;
  final String subject;
  final List<RosterEntry> entries;

  WeekPlan({required this.weekNumber, required this.subject, required this.entries});

  factory WeekPlan.fromJson(Map<String, dynamic> json) {
    var entriesJson = json['entries'] as List? ?? [];
    return WeekPlan(
      weekNumber: json['weekNumber'] ?? 1,
      subject: json['subject'] ?? '',
      entries: entriesJson.map((e) => RosterEntry.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'subject': subject,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}

class PlannerState {
  final List<WeekPlan> weeklyPlan;
  final int currentWeek;
  final String currentDay;

  PlannerState({
    required this.weeklyPlan,
    this.currentWeek = 1,
    this.currentDay = 'Monday',
  });

  factory PlannerState.fromJson(Map<String, dynamic> json) {
    var weeklyPlanJson = json['weeklyPlan'] as List? ?? [];
    return PlannerState(
      weeklyPlan: weeklyPlanJson.map((e) => WeekPlan.fromJson(e)).toList(),
      currentWeek: json['currentWeek'] ?? 1,
      currentDay: json['currentDay'] ?? 'Monday',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklyPlan': weeklyPlan.map((e) => e.toJson()).toList(),
      'currentWeek': currentWeek,
      'currentDay': currentDay,
    };
  }

  List<RosterEntry> get todayEntries {
    if (weeklyPlan.isEmpty) return [];
    var weeks = weeklyPlan.where((w) => w.weekNumber == currentWeek).toList();
    List<RosterEntry> entries = [];
    for (var w in weeks) {
      entries.addAll(w.entries.where((e) => e.day == currentDay));
    }
    return entries;
  }

  RosterEntry? get nextStudent {
    var today = todayEntries;
    try {
      return today.firstWhere((e) => e.status == RosterStatus.waiting || e.status == RosterStatus.inProgress);
    } catch (e) {
      return null;
    }
  }

  bool get isTodayComplete {
    var today = todayEntries;
    if (today.isEmpty) return false;
    return today.every((e) => e.status == RosterStatus.completed || e.status == RosterStatus.absent);
  }

  bool get isCycleComplete {
    if (weeklyPlan.isEmpty) return false;
    return weeklyPlan.every((w) => w.entries.every((e) => e.status == RosterStatus.completed || e.status == RosterStatus.absent));
  }
}
