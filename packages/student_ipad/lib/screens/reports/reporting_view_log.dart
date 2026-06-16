import 'package:flutter/material.dart';
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
              const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // Mock export
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Export to CSV'),
                      content: const Text('The response log has been successfully exported to your downloads folder.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: filtered.isEmpty
                ? const Center(child: Text('No responses found.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        columns: const [
                          DataColumn(label: Text('Timestamp')),
                          DataColumn(label: Text('Student')),
                          DataColumn(label: Text('Subject')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Question')),
                          DataColumn(label: Text('Correct?')),
                          DataColumn(label: Text('Answer Details')),
                          DataColumn(label: Text('Time (s)')),
                        ],
                        rows: filtered.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')}')),
                              DataCell(Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(r.subject)),
                              DataCell(Text(r.questionType.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 12))),
                              DataCell(SizedBox(width: 200, child: Text(r.questionText, maxLines: 2, overflow: TextOverflow.ellipsis))),
                              DataCell(
                                r.submittedAnswer == null || r.submittedAnswer == 'skipped'
                                  ? const Icon(Icons.skip_next, color: Colors.grey)
                                  : Icon(r.isCorrect ? Icons.check_circle : Icons.cancel, color: r.isCorrect ? Colors.green : Colors.red),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: r.questionType == QuestionType.verbal
                                    ? Row(
                                        children: [
                                          const Icon(Icons.mic, size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(r.submittedAnswer?.toString() ?? 'Skipped', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      )
                                    : Text(r.submittedAnswer?.toString() ?? 'Skipped', maxLines: 2, overflow: TextOverflow.ellipsis),
                                )
                              ),
                              DataCell(Text('${r.timeSpentSeconds}s')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
