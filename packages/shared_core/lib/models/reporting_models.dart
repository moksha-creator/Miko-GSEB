import 'dart:convert';
import 'package:shared_core/models/quiz_models.dart';

class QuizResponse {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final String chapter;
  final String questionId;
  final String questionText;
  final QuestionType questionType;
  final bool isCorrect;
  final dynamic submittedAnswer;
  final int timeSpentSeconds;
  final DateTime timestamp;

  QuizResponse({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.chapter,
    required this.questionId,
    required this.questionText,
    required this.questionType,
    required this.isCorrect,
    this.submittedAnswer,
    required this.timeSpentSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'subject': subject,
      'chapter': chapter,
      'questionId': questionId,
      'questionText': questionText,
      'questionType': questionType.toString(),
      'isCorrect': isCorrect,
      'submittedAnswer': _serializeAnswer(submittedAnswer),
      'timeSpentSeconds': timeSpentSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      subject: json['subject'],
      chapter: json['chapter'],
      questionId: json['questionId'],
      questionText: json['questionText'] ?? 'Unknown Question',
      questionType: QuestionType.values.firstWhere((e) => e.toString() == json['questionType']),
      isCorrect: json['isCorrect'],
      submittedAnswer: json['submittedAnswer'],
      timeSpentSeconds: json['timeSpentSeconds'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  static dynamic _serializeAnswer(dynamic answer) {
    if (answer is Map) {
      return answer.map((key, value) => MapEntry(key.toString(), value));
    }
    return answer;
  }
}
