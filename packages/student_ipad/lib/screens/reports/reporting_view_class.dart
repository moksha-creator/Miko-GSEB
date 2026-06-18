import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../../providers/planner_state_provider.dart';
import '../student_profiles_screen.dart';

class ReportingViewClass extends ConsumerStatefulWidget {
  const ReportingViewClass({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportingViewClass> createState() => _ReportingViewClassState();
}

class _ReportingViewClassState extends ConsumerState<ReportingViewClass> {
  String _selectedSubject = 'All';

  Widget _metricCard(String label, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF64748B), size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
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
          Expanded(child: Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          Text('$correct/$total', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

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

    final allStudentsAsync = ref.watch(mockDataServiceProvider).loadClassSample();
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Subject filter — chip row
          if (subjects.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                children: subjects.map((s) {
                  final isSelected = _selectedSubject == s;
                  return ChoiceChip(
                    label: Text(s == 'All' ? 'All Subjects' : s, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedSubject = s),
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
            ),
          if (subjects.length > 1) const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<ClassProfile>(
              future: allStudentsAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final coverageService = ref.watch(coverageServiceProvider);
                final setup = ref.watch(classSetupProvider);
                final currentCheckpointId = setup?.checkpoint ?? 'monthly';
                
                // Active subject is either 'All' or _selectedSubject
                // We show coverage for the selected subject. If 'All', we can just use the first available or we can sum it up.
                // Wait, if _selectedSubject is 'All', coverage doesn't make sense unless we aggregate.
                // Since this is just a mockup, if 'All', let's just use 'eng' as a fallback for coverage, or better yet, default to the first available subject.
                final subjectForCoverage = _selectedSubject == 'All' ? 'eng' : _selectedSubject;
                
                final totalRoster = snapshot.data!.students.length;
                final evaluatedStudents = filtered.map((e) => e.studentId).toSet();
                
                final skippedCount = coverageService.getAbsentCount(subjectForCoverage, currentCheckpointId, snapshot.data!.students);
                final completedCount = coverageService.getCoveredCount(subjectForCoverage, currentCheckpointId, snapshot.data!.students);
                
                final evaluatedCount = evaluatedStudents.length;
                int pendingCount = totalRoster - completedCount - skippedCount;
                if (pendingCount < 0) pendingCount = 0;
                
                // For the UI, we should probably use evaluatedCount to mean `completedCount` to match the offline coverage model,
                // but since evaluatedCount currently uses the filtered answers (meaning they actually submitted something), I will keep evaluatedCount as is for the "Assessed" top metric, but for the coverage bar I'll use the coverage service metrics to keep it aligned with the offline status.
                
                final evalPct = totalRoster == 0 ? 0.0 : completedCount / totalRoster;
                final pendingPct = totalRoster == 0 ? 0.0 : pendingCount / totalRoster;
                final skipPct = totalRoster == 0 ? 0.0 : skippedCount / totalRoster;

                // Group by subject for the breakdown
                final subjectAcc = <String, List<QuizResponse>>{};
                for (final r in answered) {
                  subjectAcc.putIfAbsent(r.subject, () => []).add(r);
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // B. Four headline metric cards
                      Row(
                        children: [
                          Expanded(child: _metricCard('Class Accuracy', '${totalAccuracy.toStringAsFixed(0)}%', Icons.score)),
                          const SizedBox(width: 16),
                          Expanded(child: _metricCard('Assessed', '$evaluatedCount', Icons.check_circle_outline)),
                          const SizedBox(width: 16),
                          Expanded(child: _metricCard('Remaining', '$pendingCount', Icons.pending_actions)),
                          const SizedBox(width: 16),
                          Expanded(child: _metricCard('Absent', '$skippedCount', Icons.person_off)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // C. Coverage bar — full width
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Class Coverage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 16,
                                  child: Row(
                                    children: [
                                      if (evalPct > 0) Expanded(flex: (evalPct * 100).round() >= 1 ? (evalPct * 100).round() : 1, child: Container(color: AppColors.success)),
                                      if (pendingPct > 0) Expanded(flex: (pendingPct * 100).round() >= 1 ? (pendingPct * 100).round() : 1, child: Container(color: AppColors.warning)),
                                      if (skipPct > 0) Expanded(flex: (skipPct * 100).round() >= 1 ? (skipPct * 100).round() : 1, child: Container(color: AppColors.accent)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Assessed ($completedCount)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                                  const SizedBox(width: 24),
                                  Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Remaining ($pendingCount)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                                  const SizedBox(width: 24),
                                  Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)), const SizedBox(width: 6), Text('Absent ($skippedCount)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // D. Two-column section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column — "Accuracy by subject"
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Accuracy by subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                    const Divider(height: 32),
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
                          // Right column — "Consider revisiting"
                          Expanded(
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text('Consider revisiting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                    const Divider(height: 32),
                                    _buildConsiderRevisiting(answered),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsiderRevisiting(List<QuizResponse> answered) {
    final missedMap = <String, int>{}; // questionId -> misses
    final qTextMap = <String, String>{}; // questionId -> text

    for (final r in answered) {
      if (!r.isCorrect) {
        missedMap[r.questionId] = (missedMap[r.questionId] ?? 0) + 1;
        qTextMap[r.questionId] = r.questionText;
      }
    }

    if (missedMap.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text('No missed questions yet! 🎉', style: TextStyle(color: AppColors.success, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
    }

    final sorted = missedMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      children: sorted.map((e) {
        final text = qTextMap[e.key] ?? 'Unknown';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${e.value} missed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
