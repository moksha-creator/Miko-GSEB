import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import 'reporting_service.dart';

class CoverageCell {
  final String status; // 'uncovered', 'covered', 'absentToday'
  final DateTime? lastAssessedDate;
  final DateTime? cooldownUntil;

  CoverageCell({
    required this.status,
    this.lastAssessedDate,
    this.cooldownUntil,
  });

  factory CoverageCell.fromJson(Map<String, dynamic> json) {
    return CoverageCell(
      status: json['status'] as String? ?? 'uncovered',
      lastAssessedDate: json['lastAssessedDate'] != null ? DateTime.tryParse(json['lastAssessedDate']) : null,
      cooldownUntil: json['cooldownUntil'] != null ? DateTime.tryParse(json['cooldownUntil']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (lastAssessedDate != null) 'lastAssessedDate': lastAssessedDate!.toIso8601String(),
      if (cooldownUntil != null) 'cooldownUntil': cooldownUntil!.toIso8601String(),
    };
  }
}

class CoverageService {
  final SharedPreferences _prefs;
  static const _keyPrefix = 'coverage_';

  CoverageService(this._prefs);

  String _key(String studentId, String checkpointId, String subjectId) {
    return '$_keyPrefix${studentId}_${checkpointId}_$subjectId';
  }

  CoverageCell _getCell(String studentId, String checkpointId, String subjectId) {
    final data = _prefs.getString(_key(studentId, checkpointId, subjectId));
    if (data == null) {
      return CoverageCell(status: 'uncovered');
    }
    try {
      return CoverageCell.fromJson(jsonDecode(data));
    } catch (e) {
      return CoverageCell(status: 'uncovered');
    }
  }

  void _saveCell(String studentId, String checkpointId, String subjectId, CoverageCell cell) {
    _prefs.setString(_key(studentId, checkpointId, subjectId), jsonEncode(cell.toJson()));
  }

  Student? assignNext({
    required List<Student> eligible,
    required String subjectId,
    required String checkpointId,
    required DateTime now,
  }) {
    List<Map<String, dynamic>> candidates = [];

    for (final student in eligible) {
      final cell = _getCell(student.id, checkpointId, subjectId);

      if (cell.status == 'covered' || cell.status == 'absentToday') continue;
      if (cell.cooldownUntil != null && cell.cooldownUntil!.isAfter(now)) continue;

      candidates.add({
        'student': student,
        'lastAssessedDate': cell.lastAssessedDate,
      });
    }

    if (candidates.isEmpty) return null;

    // Rank by debt: oldest lastAssessedDate first. Nulls are older than any date.
    candidates.sort((a, b) {
      final DateTime? dateA = a['lastAssessedDate'];
      final DateTime? dateB = b['lastAssessedDate'];

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return -1;
      if (dateB == null) return 1;
      return dateA.compareTo(dateB);
    });

    return candidates.first['student'] as Student;
  }

  void markCovered(String studentId, String checkpointId, String subjectId, DateTime date) {
    _saveCell(
      studentId,
      checkpointId,
      subjectId,
      CoverageCell(status: 'covered', lastAssessedDate: date),
    );
  }

  void defer(String studentId, String checkpointId, String subjectId, DateTime now) {
    final cell = _getCell(studentId, checkpointId, subjectId);
    _saveCell(
      studentId,
      checkpointId,
      subjectId,
      CoverageCell(
        status: cell.status == 'covered' ? 'uncovered' : cell.status,
        lastAssessedDate: cell.lastAssessedDate,
        cooldownUntil: now.add(const Duration(minutes: 5)),
      ),
    );
  }

  void markAbsentToday(String studentId, String checkpointId, String subjectId) {
    final cell = _getCell(studentId, checkpointId, subjectId);
    _saveCell(
      studentId,
      checkpointId,
      subjectId,
      CoverageCell(
        status: 'absentToday',
        lastAssessedDate: cell.lastAssessedDate,
        cooldownUntil: cell.cooldownUntil,
      ),
    );
  }

  double coveragePercent(String subjectId, String checkpointId, List<Student> roster) {
    if (roster.isEmpty) return 0.0;
    int covered = 0;
    for (final s in roster) {
      if (_getCell(s.id, checkpointId, subjectId).status == 'covered') {
        covered++;
      }
    }
    return covered / roster.length;
  }

  bool isCheckpointComplete(String subjectId, String checkpointId, List<Student> roster) {
    if (roster.isEmpty) return false;
    for (final s in roster) {
      if (_getCell(s.id, checkpointId, subjectId).status != 'covered') {
        return false;
      }
    }
    return true;
  }

  int getCoveredCount(String subjectId, String checkpointId, List<Student> roster) {
    return roster.where((s) => _getCell(s.id, checkpointId, subjectId).status == 'covered').length;
  }

  int getAbsentCount(String subjectId, String checkpointId, List<Student> roster) {
    return roster.where((s) => _getCell(s.id, checkpointId, subjectId).status == 'absentToday').length;
  }

  String getStudentStatus(String studentId, String checkpointId, String subjectId) {
    return _getCell(studentId, checkpointId, subjectId).status;
  }
}

final coverageServiceProvider = Provider<CoverageService>((ref) {
  final prefs = ref.watch(reportingSharedPreferencesProvider);
  return CoverageService(prefs);
});
