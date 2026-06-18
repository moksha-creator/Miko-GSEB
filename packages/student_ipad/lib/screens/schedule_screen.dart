import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import '../providers/planner_state_provider.dart';
import 'student_profiles_screen.dart';
import 'dart:math';

class ScheduleScreen extends ConsumerWidget {
  final ClassSetup setup;
  const ScheduleScreen({Key? key, required this.setup}) : super(key: key);

  int _getWeeks() {
    switch (setup.checkpoint) {
      case 'monthly': return 4;
      case 'quarterly': return 13;
      case 'yearly': return 40;
      default: return 4;
    }
  }

  String _getSubjectName(String subId) => Subjects.name(subId);

  IconData _getSubjectIcon(String subId) => Subjects.icon(subId);

  Color _getSubjectColor(String subId) => Subjects.color(subId);

  List<Student> _getCohortStudents(List<Student> allStudents, int cohortIndex, int studentsPerCohort) {
    final startIndex = cohortIndex * studentsPerCohort;
    final endIndex = min(startIndex + studentsPerCohort, allStudents.length);
    if (startIndex >= allStudents.length) return [];
    return allStudents.sublist(startIndex, endIndex);
  }

  int _getCohortForSubjectInWeek(int weekIndex, int subjectIndex, int totalWeeks) {
    return (weekIndex + subjectIndex) % totalWeeks;
  }

  // To find out which subjects a student missed if they are marked absent
  List<String> _getMissedSubjects(Student student, int studentIndex, int studentsPerCohort, int totalWeeks, List<String> activeSubjects) {
    int studentCohort = studentIndex ~/ studentsPerCohort;
    List<String> missed = [];
    
    // In our simplified demo, we assume the schedule hasn't fully passed yet,
    // but if they are absent, they need to make up whatever their cohort was scheduled for.
    // For a strict "what did they miss" in a stateless app, we'll just say they missed 
    // ALL subjects they were supposed to take up to the current moment.
    // Since we don't have a "current week" concept in state, we'll just show all subjects 
    // their cohort was assigned across the 4 weeks. 
    // Actually, every cohort is assigned every subject exactly once.
    // So if they are absent, they miss ALL active subjects eventually.
    // We can just list all active subjects as make-up needed.
    return activeSubjects;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(allStudentsProvider);
    final completed = ref.watch(completedStudentsProvider);
    final skipped = ref.watch(skippedStudentsProvider);

    final weeksCount = _getWeeks();
    final studentsPerCohort = (students.length / weeksCount).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Classroom Schedule to Checkpoint', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView.builder(
          itemCount: weeksCount + 1, // +1 for Floater Day
          itemBuilder: (context, index) {
            if (index == weeksCount) {
              return _buildFloaterDaySection(students, skipped, studentsPerCohort, weeksCount);
            }

            return _buildWeekCard(index, students, completed, skipped, studentsPerCohort, weeksCount);
          },
        ),
      ),
    );
  }

  Widget _buildWeekCard(int weekIndex, List<Student> students, Set<String> completed, Set<String> skipped, int studentsPerCohort, int totalWeeks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Week ${weekIndex + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
          const SizedBox(height: 24),
          ...setup.activeSubjects.asMap().entries.map((entry) {
            final subjectIndex = entry.key;
            final subjectId = entry.value;
            
            final assignedCohort = _getCohortForSubjectInWeek(weekIndex, subjectIndex, totalWeeks);
            final cohortStudents = _getCohortStudents(students, assignedCohort, studentsPerCohort);
            
            if (cohortStudents.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getSubjectIcon(subjectId), color: _getSubjectColor(subjectId)),
                      const SizedBox(width: 8),
                      Text(_getSubjectName(subjectId), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getSubjectColor(subjectId))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSubjectColor(subjectId).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Cohort ${assignedCohort + 1}', style: TextStyle(color: _getSubjectColor(subjectId), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cohortStudents.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, idx) {
                      final student = cohortStudents[idx];
                      return _buildStudentRow(student, subjectId, completed, skipped);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFloaterDaySection(List<Student> allStudents, Set<String> skipped, int studentsPerCohort, int totalWeeks) {
    final absentStudents = allStudents.where((s) => skipped.contains(s.id)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Floater Day / Catch-up', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Students marked absent will need to be assessed during a floater day or extra session.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          if (absentStudents.isEmpty)
            const Text('No absent students currently.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: absentStudents.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, idx) {
                final student = absentStudents[idx];
                final studentIndex = allStudents.indexOf(student);
                final missed = _getMissedSubjects(student, studentIndex, studentsPerCohort, totalWeeks, setup.activeSubjects);
                final missedNames = missed.map((s) => _getSubjectName(s)).join(', ');

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(student.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('Missed: $missedNames', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Make-up Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student, String subjectId, Set<String> completed, Set<String> skipped) {
    String status = 'Pending';
    Color statusColor = Colors.grey;
    Color statusBg = Colors.grey.shade100;

    if (completed.contains(student.id)) {
      status = 'Completed';
      statusColor = Colors.green;
      statusBg = Colors.green.shade50;
    } else if (skipped.contains(student.id)) {
      status = 'Absent';
      statusColor = Colors.red;
      statusBg = Colors.red.shade50;
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade100,
          child: Text(student.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
