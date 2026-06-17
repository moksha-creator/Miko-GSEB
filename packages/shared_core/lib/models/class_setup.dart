class ClassSetup {
  final String grade;
  final String section;
  final int studentCount;
  final int schoolDays;
  final String assessmentMode; // 'ded' or 'emb'
  final Map<String, int> subjectLecturesPerWeek;
  final int lectureLength;
  final List<String> activeSubjects;
  final String checkpoint;
  final int sessionsPerWeek; // 'monthly', 'quarterly', 'yearly'
  final List<String>? studentNames; // Added for manual entry

  ClassSetup({
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.schoolDays,
    required this.assessmentMode,
    required this.subjectLecturesPerWeek,
    required this.lectureLength,
    required this.activeSubjects,
    required this.checkpoint,
    this.sessionsPerWeek = 2,
    this.studentNames,
  });

  int get checkpointWindowWeeks {
    switch (checkpoint) {
      case 'monthly': return 4;
      case 'quarterly': return 13;
      case 'yearly': return 40;
      default: return 4;
    }
  }

  factory ClassSetup.fromJson(Map<String, dynamic> json) {
    return ClassSetup(
      grade: json['grade']?.toString() ?? '5',
      section: json['section'] ?? 'B',
      studentCount: json['studentCount'] ?? 40,
      schoolDays: json['schoolDays'] ?? 5,
      assessmentMode: json['assessmentMode'] ?? 'ded',
      subjectLecturesPerWeek: json['subjectLecturesPerWeek'] != null 
          ? Map<String, int>.from(json['subjectLecturesPerWeek'])
          : {'math': 4, 'sci': 4, 'lang': 4, 'soc': 4},
      lectureLength: json['lectureLength'] ?? 45,
      activeSubjects: List<String>.from(json['activeSubjects'] ?? []),
      checkpoint: json['checkpoint'] ?? 'monthly',
      sessionsPerWeek: json['sessionsPerWeek'] ?? 2,
      studentNames: json['studentNames'] != null ? List<String>.from(json['studentNames']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'section': section,
      'studentCount': studentCount,
      'schoolDays': schoolDays,
      'assessmentMode': assessmentMode,
      'subjectLecturesPerWeek': subjectLecturesPerWeek,
      'lectureLength': lectureLength,
      'activeSubjects': activeSubjects,
      'checkpoint': checkpoint,
      'studentNames': studentNames,
      'sessionsPerWeek': sessionsPerWeek,
    };
  }

  ClassSetup copyWith({
    String? grade,
    String? section,
    int? studentCount,
    int? schoolDays,
    String? assessmentMode,
    Map<String, int>? subjectLecturesPerWeek,
    int? lectureLength,
    List<String>? activeSubjects,
    String? checkpoint,
    List<String>? studentNames,
    int? sessionsPerWeek,
  }) {
    return ClassSetup(
      grade: grade ?? this.grade,
      section: section ?? this.section,
      studentCount: studentCount ?? this.studentCount,
      schoolDays: schoolDays ?? this.schoolDays,
      assessmentMode: assessmentMode ?? this.assessmentMode,
      subjectLecturesPerWeek: subjectLecturesPerWeek ?? this.subjectLecturesPerWeek,
      lectureLength: lectureLength ?? this.lectureLength,
      activeSubjects: activeSubjects ?? this.activeSubjects,
      checkpoint: checkpoint ?? this.checkpoint,
      studentNames: studentNames ?? this.studentNames,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
    );
  }
}
