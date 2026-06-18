import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../providers/planner_state_provider.dart';

class ReportingViewStudent extends ConsumerStatefulWidget {
  const ReportingViewStudent({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportingViewStudent> createState() => _ReportingViewStudentState();
}

class _ReportingViewStudentState extends ConsumerState<ReportingViewStudent> {
  String? _selectedStudentId;
  bool _isExpanded = false;

  String _shortName(String full) {
    final parts = full.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts.last[0]}.';
  }

  String _checkpointLabel(String checkpoint) {
    switch (checkpoint) {
      case 'monthly': return 'end-of-month';
      case 'quarterly': return 'end-of-term';
      case 'yearly': return 'end-of-year';
      default: return 'checkpoint';
    }
  }

  Widget _subjectRow(String subject, int correct, int total) {
    final pct = total == 0 ? 0.0 : (correct / total) * 100;
    final color = pct >= 75
        ? AppColors.success
        : (pct >= 50 ? AppColors.warning : AppColors.accent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(subject,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Text('$correct/$total',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responses = ref.watch(reportingServiceProvider).getAllResponses();
    // Unique students from responses
    final studentsMap = <String, String>{};
    for (final r in responses) {
      studentsMap[r.studentId] = r.studentName;
    }
    
    final studentList = studentsMap.entries.toList();
    if (_selectedStudentId == null && studentList.isNotEmpty) {
      _selectedStudentId = studentList.first.key;
    }

    final studentResponses = responses.where((r) => r.studentId == _selectedStudentId).toList();
    final answered = studentResponses.where((r) => r.submittedAnswer != null && r.submittedAnswer != 'skipped').toList();
    final skipped = studentResponses.where((r) => r.submittedAnswer == null || r.submittedAnswer == 'skipped').toList();
    final correct = answered.where((r) => r.isCorrect).toList();
    
    final totalAccuracy = answered.isEmpty ? 0.0 : (correct.length / answered.length) * 100;
    
    double avgTime = 0;
    if (answered.isNotEmpty) {
      final totalSeconds = answered.fold<int>(0, (sum, r) => sum + r.timeSpentSeconds);
      avgTime = totalSeconds / answered.length;
    }

    // Group by Subject
    final subjectAcc = <String, List<QuizResponse>>{};
    for (final r in answered) {
      subjectAcc.putIfAbsent(r.subject, () => []).add(r);
    }

    // Group by Type
    final typeAcc = <QuestionType, List<QuizResponse>>{};
    for (final r in answered) {
      typeAcc.putIfAbsent(r.questionType, () => []).add(r);
    }

    // Checkpoint signal logic
    final setup = ref.watch(classSetupProvider);
    String checkpointLine = '';
    Color checkpointColor = AppColors.success;
    if (setup != null) {
      final windowWeeks = setup.checkpointWindowWeeks;
      final weeksNeeded = PlannerService().calculateWeeksNeeded(setup);
      final completedSubjects = studentResponses.map((r) => r.subject).toSet().length;
      final remainingSubjects = setup.activeSubjects.length - completedSubjects;
      if (remainingSubjects <= 0) {
        checkpointLine = 'All subjects assessed ✓';
        checkpointColor = AppColors.success;
      } else if (weeksNeeded <= windowWeeks) {
        checkpointLine = 'On track for ${_checkpointLabel(setup.checkpoint)} ✓';
        checkpointColor = AppColors.success;
      } else {
        final diff = weeksNeeded - windowWeeks;
        checkpointLine = 'Behind — $diff week(s) over ${_checkpointLabel(setup.checkpoint)}';
        checkpointColor = AppColors.accent;
      }
    }

    List<MapEntry<String, String>> displayedStudents = studentList;
    if (!_isExpanded && studentList.length > 8) {
      displayedStudents = studentList.take(8).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Student selector — chip row
          if (studentList.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Wrap(
                    spacing: 8,
                    children: displayedStudents.map((s) {
                      final displayName = _shortName(s.value);
                      final isSelected = _selectedStudentId == s.key;
                      return ChoiceChip(
                        label: Text(displayName, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedStudentId = s.key),
                        selectedColor: AppColors.primaryLight,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                  if (!_isExpanded && studentList.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _isExpanded = true),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text('+${studentList.length - 8} more', style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          if (studentList.isEmpty)
            const Expanded(child: Center(child: Text('No assessment data captured yet.', style: TextStyle(color: AppColors.textSecondary))))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // B. Hero accuracy block
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${totalAccuracy.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                            const Text('Overall accuracy', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text('${answered.length} answered · ${skipped.length} skipped · ${avgTime.toStringAsFixed(0)}s avg per question', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: totalAccuracy / 100,
                              backgroundColor: AppColors.surface,
                              color: totalAccuracy >= 75 ? AppColors.success : (totalAccuracy >= 50 ? AppColors.warning : AppColors.accent),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            if (checkpointLine.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.flag, color: checkpointColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(checkpointLine, style: TextStyle(color: checkpointColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // C. Accuracy by subject
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Accuracy by Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                  const Divider(),
                                  if (subjectAcc.isEmpty) const Text('No data', style: TextStyle(color: AppColors.textMuted)),
                                  ...subjectAcc.entries.map((e) {
                                    final total = e.value.length;
                                    final c = e.value.where((r) => r.isCorrect).length;
                                    return _subjectRow(e.key, c, total);
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // D. Question types
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Question types', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                  const Divider(),
                                  if (typeAcc.isEmpty) const Text('No data', style: TextStyle(color: AppColors.textMuted)),
                                  ...typeAcc.entries.map((e) {
                                    final total = e.value.length;
                                    final c = e.value.where((r) => r.isCorrect).length;
                                    final pct = (c / total) * 100;
                                    Color barColor = pct >= 75 ? AppColors.success : (pct >= 50 ? AppColors.warning : AppColors.accent);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(e.key.toString().split('.').last.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: pct / 100,
                                            backgroundColor: AppColors.surface,
                                            color: barColor,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
