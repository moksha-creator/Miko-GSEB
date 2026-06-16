import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

class ReportingViewStudent extends ConsumerStatefulWidget {
  const ReportingViewStudent({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportingViewStudent> createState() => _ReportingViewStudentState();
}

class _ReportingViewStudentState extends ConsumerState<ReportingViewStudent> {
  String? _selectedStudentId;

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

    // Group by Type (Template Family)
    final typeAcc = <QuestionType, List<QuizResponse>>{};
    for (final r in answered) {
      typeAcc.putIfAbsent(r.questionType, () => []).add(r);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Controls
          Row(
            children: [
              const Text('Select Student:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButton<String>(
                  value: _selectedStudentId,
                  underline: const SizedBox(),
                  hint: const Text('No data yet'),
                  items: studentList.map((s) => DropdownMenuItem(value: s.key, child: Text(s.value))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStudentId = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (studentList.isEmpty)
            const Expanded(child: Center(child: Text('No assessment data captured yet.')))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Metrics Row
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Overall Accuracy', '${totalAccuracy.toStringAsFixed(1)}%', Icons.score)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Answered', '${answered.length}', Icons.check_circle_outline)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Skipped', '${skipped.length}', Icons.skip_next)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Avg Time / Q', '${avgTime.toStringAsFixed(1)}s', Icons.timer)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Accuracy
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
                                  const Text('Accuracy by Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Divider(),
                                  if (subjectAcc.isEmpty) const Text('No data'),
                                  ...subjectAcc.entries.map((e) {
                                    final total = e.value.length;
                                    final c = e.value.where((r) => r.isCorrect).length;
                                    final pct = (c / total) * 100;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(e.key),
                                          Text('${pct.toStringAsFixed(0)}% ($c/$total)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Template Family Accuracy
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
                                  const Text('Template Family Mastery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Divider(),
                                  if (typeAcc.isEmpty) const Text('No data'),
                                  ...typeAcc.entries.map((e) {
                                    final total = e.value.length;
                                    final c = e.value.where((r) => r.isCorrect).length;
                                    final pct = (c / total) * 100;
                                    Color barColor = pct >= 80 ? Colors.green : (pct >= 50 ? Colors.orange : Colors.red);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(e.key.toString().split('.').last.toUpperCase()),
                                              Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: pct / 100,
                                            backgroundColor: Colors.grey.shade200,
                                            color: barColor,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
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

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
