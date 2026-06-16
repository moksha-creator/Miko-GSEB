import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../student_profiles_screen.dart';

class ReportingViewClass extends ConsumerStatefulWidget {
  const ReportingViewClass({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportingViewClass> createState() => _ReportingViewClassState();
}

class _ReportingViewClassState extends ConsumerState<ReportingViewClass> {
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    final responses = ref.watch(reportingServiceProvider).getAllResponses();
    
    final subjects = {'All'};
    for (final r in responses) {
      subjects.add(r.subject);
    }

    final filtered = _selectedSubject == 'All' ? responses : responses.where((r) => r.subject == _selectedSubject).toList();
    final answered = filtered.where((r) => r.submittedAnswer != null && r.submittedAnswer != 'skipped').toList();
    final correct = answered.where((r) => r.isCorrect).toList();
    
    final totalAccuracy = answered.isEmpty ? 0.0 : (correct.length / answered.length) * 100;

    // Coverage Strip
    final allStudentsAsync = ref.watch(mockDataServiceProvider).loadClassSample();
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters
          Row(
            children: [
              const Text('Filter Subject:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  underline: const SizedBox(),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubject = val!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 24),
              const Text('Overall Accuracy:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('${totalAccuracy.toStringAsFixed(1)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: totalAccuracy >= 70 ? Colors.green : Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Coverage Strip & Template Family
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Coverage Strip
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: FutureBuilder<ClassProfile>(
                            future: allStudentsAsync,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const CircularProgressIndicator();
                              
                              final totalRoster = snapshot.data!.students.length;
                              final evaluatedStudents = filtered.map((e) => e.studentId).toSet();
                              final skippedIds = ref.watch(skippedStudentsProvider);
                              
                              final evaluatedCount = evaluatedStudents.length;
                              final skippedCount = skippedIds.length;
                              final pendingCount = totalRoster - evaluatedCount - skippedCount;
                              
                              final evalPct = totalRoster == 0 ? 0.0 : evaluatedCount / totalRoster;
                              final pendingPct = totalRoster == 0 ? 0.0 : pendingCount / totalRoster;
                              final skipPct = totalRoster == 0 ? 0.0 : skippedCount / totalRoster;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Coverage Strip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      height: 24,
                                      child: Row(
                                        children: [
                                          if (evalPct > 0) Expanded(flex: (evalPct * 100).round(), child: Container(color: Colors.green)),
                                          if (pendingPct > 0) Expanded(flex: (pendingPct * 100).round(), child: Container(color: Colors.amber)),
                                          if (skipPct > 0) Expanded(flex: (skipPct * 100).round(), child: Container(color: Colors.red.shade400)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildLegend('Assessed', Colors.green, evaluatedCount),
                                      _buildLegend('Pending', Colors.amber, pendingCount),
                                      _buildLegend('Absent/Skip', Colors.red.shade400, skippedCount),
                                    ],
                                  )
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Breakdown by template family
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Class Breakdown by Template Family', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Divider(),
                                Expanded(
                                  child: ListView(
                                    children: QuestionType.values.map((qt) {
                                      final items = answered.where((r) => r.questionType == qt).toList();
                                      if (items.isEmpty) return const SizedBox.shrink();
                                      final correctCount = items.where((r) => r.isCorrect).length;
                                      final pct = (correctCount / items.length) * 100;
                                      return ListTile(
                                        title: Text(qt.toString().split('.').last.toUpperCase()),
                                        trailing: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: pct >= 70 ? Colors.green : Colors.red)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Most Missed Questions
                Expanded(
                  flex: 1,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Most-Missed Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          Expanded(
                            child: _buildMostMissed(answered),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMostMissed(List<QuizResponse> answered) {
    final missedMap = <String, int>{}; // questionId -> misses
    final qTextMap = <String, String>{}; // questionId -> text

    for (final r in answered) {
      if (!r.isCorrect) {
        missedMap[r.questionId] = (missedMap[r.questionId] ?? 0) + 1;
        qTextMap[r.questionId] = r.questionText;
      }
    }

    if (missedMap.isEmpty) {
      return const Center(child: Text('No missed questions yet! 🎉', style: TextStyle(color: Colors.green, fontSize: 16)));
    }

    final sorted = missedMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final e = sorted[index];
        final text = qTextMap[e.key] ?? 'Unknown';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                child: Text('${e.value}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Misses', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
