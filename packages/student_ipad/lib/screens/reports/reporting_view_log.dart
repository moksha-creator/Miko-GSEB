import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

class ReportingViewLog extends ConsumerStatefulWidget {
  const ReportingViewLog({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportingViewLog> createState() => _ReportingViewLogState();
}

class _ReportingViewLogState extends ConsumerState<ReportingViewLog> {
  String _selectedSubject = 'All';
  String _selectedStudent = 'All';
  String _selectedResult = 'All';

  String _toCsv(List<QuizResponse> rows) {
    if (rows.isEmpty) return 'Student,Subject,Question,Result';
    final sb = StringBuffer();
    sb.writeln('Student,Subject,Question,Result');
    for (final r in rows) {
      final isSkipped = r.submittedAnswer == null || r.submittedAnswer == 'skipped';
      final result = isSkipped ? 'Skipped' : (r.isCorrect ? 'Correct' : 'Wrong');
      // Escape question text
      final text = '"${r.questionText.replaceAll('"', '""')}"';
      sb.writeln('${r.studentName},${r.subject},$text,$result');
    }
    return sb.toString();
  }

  Future<void> _exportCsv(List<QuizResponse> rows) async {
    final csv = _toCsv(rows);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${rows.length} rows copied to clipboard — paste into Sheets or Excel'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _logRow(QuizResponse r) {
    final resultColor = (r.submittedAnswer == null || r.submittedAnswer == 'skipped')
        ? AppColors.warning
        : (r.isCorrect ? AppColors.success : AppColors.accent);
    final resultText = (r.submittedAnswer == null || r.submittedAnswer == 'skipped') ? '—' : (r.isCorrect ? '✓' : '✗');
    final resultLabel = (r.submittedAnswer == null || r.submittedAnswer == 'skipped') ? 'Skip' : (r.isCorrect ? 'Correct' : 'Wrong');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.background, width: 1)),
      ),
      child: Row(
        children: [
          // Student + question
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(r.questionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Subject
          SizedBox(
            width: 90,
            child: Text(r.subject,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          // Result badge
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(resultText,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: resultColor, fontSize: 13)),
                const SizedBox(width: 4),
                Text(resultLabel,
                    style: TextStyle(
                        fontSize: 11, color: resultColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allResponses = ref.watch(reportingServiceProvider).getAllResponses().reversed.toList();
    
    final subjects = {'All'};
    final students = {'All'};
    for (final r in allResponses) {
      subjects.add(r.subject);
      students.add(r.studentName);
    }

    final filtered = allResponses.where((r) {
      if (_selectedSubject != 'All' && r.subject != _selectedSubject) return false;
      if (_selectedStudent != 'All' && r.studentName != _selectedStudent) return false;
      
      if (_selectedResult == 'Correct' && ((r.submittedAnswer == null || r.submittedAnswer == 'skipped') || !r.isCorrect)) return false;
      if (_selectedResult == 'Wrong'   && ((r.submittedAnswer == null || r.submittedAnswer == 'skipped') || r.isCorrect))  return false;
      if (_selectedResult == 'Skipped' && !(r.submittedAnswer == null || r.submittedAnswer == 'skipped')) return false;
      
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Row(
            children: [
              const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  underline: const SizedBox(),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All Subjects' : s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubject = val!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: DropdownButton<String>(
                  value: _selectedStudent,
                  underline: const SizedBox(),
                  items: students.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All Students' : s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStudent = val!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: DropdownButton<String>(
                  value: _selectedResult,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Results')),
                    DropdownMenuItem(value: 'Correct', child: Text('Correct')),
                    DropdownMenuItem(value: 'Wrong', child: Text('Wrong')),
                    DropdownMenuItem(value: 'Skipped', child: Text('Skipped')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedResult = val!;
                    });
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _exportCsv(filtered),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.background),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(child: Text('Student · Question',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted))),
                        SizedBox(width: 90, child: Text('Subject',
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted))),
                        SizedBox(width: 72, child: Text('Result',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted))),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No responses match the filters.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) => _logRow(filtered[i]),
                          ),
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
