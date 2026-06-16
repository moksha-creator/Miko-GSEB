import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final bool isEditMode;
  const OnboardingScreen({Key? key, this.isEditMode = false}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String grade = '5';
  String section = 'B';
  int studentCount = 40;
  int schoolDays = 5;
  String mode = 'ded'; 
  Map<String, int> subjectLecturesPerWeek = {'math': 4, 'sci': 4, 'lang': 4, 'soc': 4};
  int lectureLength = 45;
  Set<String> activeSubjects = {'math', 'sci', 'lang', 'soc'};
  String checkpoint = 'monthly';
  
  bool isManualRoster = false;
  List<TextEditingController> _nameControllers = [];
  final TextEditingController _studentCountController = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    _syncNameControllers();
  }

  void _syncNameControllers() {
    if (_nameControllers.length < studentCount) {
      int diff = studentCount - _nameControllers.length;
      for (int i = 0; i < diff; i++) {
        _nameControllers.add(TextEditingController());
      }
    } else if (_nameControllers.length > studentCount) {
      int diff = _nameControllers.length - studentCount;
      for (int i = 0; i < diff; i++) {
        _nameControllers.last.dispose();
        _nameControllers.removeLast();
      }
    }
  }

  @override
  void dispose() {
    _studentCountController.dispose();
    for (var c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  final List<Map<String, dynamic>> _allSubjects = [
    {'id': 'math', 'name': 'Mathematics', 'c': const Color(0xFFD97706)},
    {'id': 'sci', 'name': 'Science', 'c': const Color(0xFF059669)},
    {'id': 'lang', 'name': 'Language', 'c': const Color(0xFF2563EB)},
    {'id': 'soc', 'name': 'Social Studies', 'c': const Color(0xFF7C3AED)},
  ];

  void _checkFeasibility() {
    List<String>? names;
    if (isManualRoster) {
      names = _nameControllers.map((c) => c.text).toList();
    }

    final setup = ClassSetup(
      grade: grade,
      section: section,
      studentCount: studentCount,
      schoolDays: schoolDays,
      assessmentMode: mode,
      subjectLecturesPerWeek: Map.from(subjectLecturesPerWeek),
      lectureLength: lectureLength,
      activeSubjects: activeSubjects.toList(),
      checkpoint: checkpoint,
      studentNames: names,
    );
    context.push('/feasibility', extra: setup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Class Setup', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                children: [
                  const Text('Grade & Division', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => grade = v,
                          controller: TextEditingController(text: grade),
                          decoration: InputDecoration(
                            labelText: 'Grade/Standard',
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => section = v,
                          controller: TextEditingController(text: section),
                          decoration: InputDecoration(
                            labelText: 'Division/Section',
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('School Days per Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('5 Days'),
                          value: 5,
                          groupValue: schoolDays,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => schoolDays = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('6 Days'),
                          value: 6,
                          groupValue: schoolDays,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => schoolDays = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text('Student Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            isManualRoster = false;
                            studentCount = 40;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                              border: Border.all(color: !isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.cloud_download_outlined, color: AppColors.primary),
                                SizedBox(height: 8),
                                Text('Import from MIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            isManualRoster = true;
                            _syncNameControllers();
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                              border: Border.all(color: isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.edit_note_outlined, color: AppColors.primary),
                                SizedBox(height: 8),
                                Text('Add Manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (isManualRoster) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of Students', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _studentCountController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            onChanged: (v) {
                              int? val = int.tryParse(v);
                              if (val != null && val > 0 && val <= 200) {
                                setState(() {
                                  studentCount = val;
                                  _syncNameControllers();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(studentCount, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextField(
                          controller: _nameControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Student ${i + 1} Name',
                            filled: true, fillColor: Colors.white,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
                          ),
                        ),
                      );
                    }),
                  ] else ...[
                    const Text('Importing 40 students from school MIS records.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  
                  const SizedBox(height: 32),

                  const Text('Subjects to Assess', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ..._allSubjects.map((sub) {
                    final isChecked = activeSubjects.contains(sub['id']);
                    return CheckboxListTile(
                      title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      value: isChecked,
                      activeColor: sub['c'],
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) activeSubjects.add(sub['id']);
                          else if (activeSubjects.length > 1) activeSubjects.remove(sub['id']);
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 32),

                  const Text('Checkpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('The deadline by which every student must finish every selected subject.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: checkpoint,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly (~4 weeks)')),
                      DropdownMenuItem(value: 'quarterly', child: Text('Quarterly (~13 weeks)')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly (~40 weeks)')),
                    ],
                    onChanged: (v) => setState(() => checkpoint = v!),
                  ),
                  const SizedBox(height: 32),

                  const Text('Assessment Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => mode = 'ded'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: mode == 'ded' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                              border: Border.all(color: mode == 'ded' ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('Dedicated Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => mode = 'emb'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: mode == 'emb' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                              border: Border.all(color: mode == 'emb' ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(child: Text('Within a Lecture', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (mode == 'emb') ...[
                    const Text('Lectures per Week (Per Subject)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Different subjects meet at different frequencies.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ...activeSubjects.map((subId) {
                      final sub = _allSubjects.firstWhere((s) => s['id'] == subId);
                      final val = subjectLecturesPerWeek[subId] ?? 4;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                              Text('$val Lectures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sub['c'])),
                            ],
                          ),
                          Slider(
                            value: val.toDouble(),
                            min: 1, max: 10, divisions: 9,
                            activeColor: sub['c'],
                            onChanged: (v) => setState(() => subjectLecturesPerWeek[subId] = v.round()),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lecture length (min)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                        Text('$lectureLength', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                    Slider(
                      value: lectureLength.toDouble(),
                      min: 30, max: 60, divisions: 6,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => lectureLength = v.round()),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkFeasibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Check Feasibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
