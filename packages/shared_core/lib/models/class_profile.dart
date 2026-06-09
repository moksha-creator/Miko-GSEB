import 'student.dart';

class ClassProfile {
  final int grade;
  final String section;
  final List<Student> students;

  ClassProfile({
    required this.grade,
    required this.section,
    required this.students,
  });

  factory ClassProfile.fromJson(Map<String, dynamic> json) {
    return ClassProfile(
      grade: json['grade'] as int,
      section: json['section'] as String,
      students: (json['students'] as List).map((e) => Student.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
