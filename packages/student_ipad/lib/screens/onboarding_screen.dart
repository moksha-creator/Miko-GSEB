import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_state_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late ClassSetup draft;
  final PlannerService _planner = PlannerService();

  bool _isManualRoster = false;
  final TextEditingController _pasteController = TextEditingController();
  bool _showRosterReview = false;

  final List<Map<String, dynamic>> _allSubjects = [
    {'id': 'math', 'name': 'Mathematics', 'c': const Color(0xFFD97706)},
    {'id': 'eng', 'name': 'English', 'c': const Color(0xFF2563EB)},
    {'id': 'guj', 'name': 'Gujarati', 'c': const Color(0xFF7C3AED)},
    {'id': 'evs', 'name': 'EVS', 'c': const Color(0xFF059669)},
  ];

  @override
  void initState() {
    super.initState();
    final existing = ref.read(classSetupProvider);
    if (existing != null) {
      draft = existing;
      if (draft.studentNames != null && draft.studentNames!.isNotEmpty) {
        _isManualRoster = true;
        _pasteController.text = draft.studentNames!.join('\n');
      }
    } else {
      draft = ClassSetup(
        grade: '5',
        section: 'B',
        studentCount: 40,
        schoolDays: 5,
        assessmentMode: 'ded',
        subjectLecturesPerWeek: {'math': 4, 'eng': 4, 'guj': 4, 'evs': 4},
        lectureLength: 45,
        activeSubjects: ['math', 'eng', 'guj', 'evs'],
        checkpoint: 'monthly',
      );
    }
    _pasteController.addListener(_onPastedNamesChanged);
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _onPastedNamesChanged() {
    if (!_isManualRoster) return;
    final text = _pasteController.text;
    final lines = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    setState(() {
      draft = draft.copyWith(
        studentCount: lines.isNotEmpty ? lines.length : 40,
        studentNames: lines.isNotEmpty ? lines : null,
      );
    });
  }

  void _updateDraft(ClassSetup newDraft) {
    setState(() {
      draft = newDraft;
    });
  }

  void _confirm() async {
    await ref.read(classSetupProvider.notifier).save(draft);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final bool fits = _planner.isFeasible(draft);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Class Setup', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 800;
            
            Widget settingsList = ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              children: [
                _buildGradeAndDivision(),
                const SizedBox(height: 32),
                _buildRosterSection(),
                const SizedBox(height: 32),
                _buildSubjectsSection(),
                const SizedBox(height: 32),
                _buildCheckpointSection(),
                const SizedBox(height: 32),
                _buildSlotSection(),
                const SizedBox(height: 32),
                _buildAdvancedSection(),
                if (!isWide) const SizedBox(height: 200), // padding for bottom sheet
              ],
            );

            Widget feasibilityPanel = _buildFeasibilityPanel(fits);

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: settingsList),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-4, 0))],
                      ),
                      child: feasibilityPanel,
                    ),
                  ),
                ],
              );
            } else {
              return Stack(
                children: [
                  settingsList,
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: SingleChildScrollView(child: feasibilityPanel),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildGradeAndDivision() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grade & Division', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grade', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.12))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: draft.grade,
                      items: List.generate(10, (i) => DropdownMenuItem(value: '${i+1}', child: Text('${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)))),
                      onChanged: (v) => _updateDraft(draft.copyWith(grade: v!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Division', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: ['A', 'B', 'C', 'D', 'E'].map((div) {
                      bool sel = draft.section == div;
                      return ChoiceChip(
                        label: Text(div),
                        selected: sel,
                        onSelected: (val) {
                          if (val) _updateDraft(draft.copyWith(section: div));
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, color: sel ? AppColors.primary : AppColors.textSecondary),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isManualRoster = false;
                    _showRosterReview = false;
                    _updateDraft(draft.copyWith(studentCount: 40, studentNames: null));
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !_isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                    border: Border.all(color: !_isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_download_outlined, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text('${_isManualRoster ? 40 : draft.studentCount} imported from MIS', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isManualRoster = true;
                    _showRosterReview = true;
                    _onPastedNamesChanged();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                    border: Border.all(color: _isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.edit_note_outlined, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text('Paste Names', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isManualRoster && _showRosterReview) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _pasteController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Paste one name per line...',
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.12))),
            ),
          ),
          const SizedBox(height: 4),
          Text('Total: ${draft.studentCount} students', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  Widget _buildSubjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subjects to Assess', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('${draft.activeSubjects.length} subjects -> Base ${draft.activeSubjects.length} weeks per round (if ded. slot)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        ..._allSubjects.map((sub) {
          final isChecked = draft.activeSubjects.contains(sub['id']);
          return CheckboxListTile(
            title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            value: isChecked,
            activeColor: sub['c'],
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) {
              var newSubjects = List<String>.from(draft.activeSubjects);
              if (v == true) newSubjects.add(sub['id']);
              else if (newSubjects.length > 1) newSubjects.remove(sub['id']);
              _updateDraft(draft.copyWith(activeSubjects: newSubjects));
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCheckpointSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Checkpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Deadline is ${draft.checkpointWindowWeeks} weeks out', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: draft.checkpoint,
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
          onChanged: (v) => _updateDraft(draft.copyWith(checkpoint: v!)),
        ),
      ],
    );
  }

  Widget _buildSlotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assessment Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(draft.assessmentMode == 'ded' ? 'Dedicated slot -> ~${(draft.schoolDays-1)*10} students/wk' : 'Within lecture -> Variable per subject', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _updateDraft(draft.copyWith(assessmentMode: 'ded')),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: draft.assessmentMode == 'ded' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                    border: Border.all(color: draft.assessmentMode == 'ded' ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Dedicated Slot', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _updateDraft(draft.copyWith(assessmentMode: 'emb')),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: draft.assessmentMode == 'emb' ? AppColors.primary.withOpacity(0.08) : Colors.white,
                    border: Border.all(color: draft.assessmentMode == 'emb' ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Within a Lecture', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return ExpansionTile(
      title: const Text('Advanced — set automatically', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Text('School Days per Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            ChoiceChip(
              label: const Text('5'),
              selected: draft.schoolDays == 5,
              onSelected: (v) { if (v) _updateDraft(draft.copyWith(schoolDays: 5)); },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('6'),
              selected: draft.schoolDays == 6,
              onSelected: (v) { if (v) _updateDraft(draft.copyWith(schoolDays: 6)); },
            ),
          ],
        ),
        if (draft.assessmentMode == 'emb') ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lecture length (min)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              Text('${draft.lectureLength}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
            ],
          ),
          Slider(
            value: draft.lectureLength.toDouble(),
            min: 30, max: 60, divisions: 6,
            activeColor: AppColors.primary,
            onChanged: (v) => _updateDraft(draft.copyWith(lectureLength: v.round())),
          ),
          const SizedBox(height: 16),
          const Text('Lectures per Week (Per Subject)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...draft.activeSubjects.map((subId) {
            final sub = _allSubjects.firstWhere((s) => s['id'] == subId, orElse: () => {'name': subId, 'c': Colors.blue});
            final val = draft.subjectLecturesPerWeek[subId] ?? 4;
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
                  onChanged: (v) {
                    var newMap = Map<String, int>.from(draft.subjectLecturesPerWeek);
                    newMap[subId] = v.round();
                    _updateDraft(draft.copyWith(subjectLecturesPerWeek: newMap));
                  },
                ),
              ],
            );
          }).toList(),
        ]
      ],
    );
  }

  Widget _buildFeasibilityPanel(bool fits) {
    int throughput = 0;
    int weeksNeeded = _planner.calculateWeeksNeeded(draft);
    int window = draft.checkpointWindowWeeks;
    int totalTime = draft.studentCount * draft.activeSubjects.length * 5;
    
    String? bottleneckSubjectId = _planner.getBottleneckSubject(draft);
    String bottleneckName = '';
    if (bottleneckSubjectId != null) {
      bottleneckName = _allSubjects.firstWhere((s) => s['id'] == bottleneckSubjectId, orElse: () => {'name': bottleneckSubjectId})['name'];
    } else {
      throughput = _planner.calculateThroughput(draft);
    }

    final verdictColor = fits ? AppColors.success : AppColors.accent;
    final verdictTitle = fits ? 'GOAL IS REACHABLE' : 'GOAL IS NOT REACHABLE';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: verdictColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: verdictColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(fits ? Icons.check_circle : Icons.warning_rounded, color: verdictColor, size: 20),
                    const SizedBox(width: 8),
                    Text(verdictTitle, style: TextStyle(fontWeight: FontWeight.w900, color: verdictColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  fits ? 'Every student can finish all ${draft.activeSubjects.length} subjects before the $window-week deadline.'
                       : (bottleneckSubjectId != null 
                            ? '$bottleneckName is your bottleneck, requiring $weeksNeeded weeks. Your checkpoint is in $window weeks.'
                            : 'It will take $weeksNeeded weeks to assess everyone, but the checkpoint is in $window weeks.'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniMetric('Weeks Needed', '$weeksNeeded wks', verdictColor),
                    const SizedBox(width: 16),
                    _buildMiniMetric('Checkpoint', '$window wks', AppColors.textPrimary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Throughput & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (draft.assessmentMode == 'ded')
            _buildDetailRow('Students per week', '$throughput', 'Derived from your assessment slot')
          else ...draft.activeSubjects.map((subId) {
            int subTp = _planner.calculateThroughput(draft, subjectId: subId);
            String subName = _allSubjects.firstWhere((s) => s['id'] == subId, orElse: () => {'name': subId})['name'];
            return _buildDetailRow('$subName Throughput', '$subTp/wk', 'Parallel embedded assessments');
          }),
          _buildDetailRow('Total assessment time', '$totalTime min', 'For one full round of the class'),
          
          if (!fits) ...[
            const SizedBox(height: 24),
            const Text('Suggested Adjustments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            
            if (draft.assessmentMode == 'emb')
              _buildAdjustment(
                'Switch to Dedicated Slot', 
                'Increases global throughput to ${(draft.schoolDays - 1) * 10}/week.',
                () => _updateDraft(draft.copyWith(assessmentMode: 'ded')),
              )
            else if (draft.schoolDays == 5)
              _buildAdjustment(
                'Switch to 6-day week', 
                'Increases throughput to 50/week.',
                () => _updateDraft(draft.copyWith(schoolDays: 6)),
              ),
              
            if (draft.checkpoint == 'monthly')
              _buildAdjustment(
                'Extend Checkpoint to Quarterly', 
                'Gives you 13 weeks instead of 4.',
                () => _updateDraft(draft.copyWith(checkpoint: 'quarterly')),
              )
            else if (draft.checkpoint == 'quarterly')
              _buildAdjustment(
                'Extend Checkpoint to Yearly', 
                'Gives you 40 weeks instead of 13.',
                () => _updateDraft(draft.copyWith(checkpoint: 'yearly')),
              ),
              
            if (draft.activeSubjects.length > 1)
              _buildAdjustment(
                bottleneckSubjectId != null ? 'Drop $bottleneckName' : 'Assess Fewer Subjects', 
                'Save ${draft.studentCount * 5} min/round.',
                () {
                  var newSubjects = List<String>.from(draft.activeSubjects);
                  if (bottleneckSubjectId != null && newSubjects.contains(bottleneckSubjectId)) {
                    newSubjects.remove(bottleneckSubjectId);
                  } else {
                    newSubjects.removeLast();
                  }
                  _updateDraft(draft.copyWith(activeSubjects: newSubjects));
                },
              ),
              
            if (draft.assessmentMode == 'emb' && bottleneckSubjectId != null)
              if ((draft.subjectLecturesPerWeek[bottleneckSubjectId] ?? 0) < 10)
                _buildAdjustment(
                  'Embed More $bottleneckName', 
                  'Add 1 more lecture per week.',
                  () {
                    var newMap = Map<String, int>.from(draft.subjectLecturesPerWeek);
                    newMap[bottleneckSubjectId] = (newMap[bottleneckSubjectId] ?? 4) + 1;
                    _updateDraft(draft.copyWith(subjectLecturesPerWeek: newMap));
                  },
                ),
          ],
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: fits ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: fits ? AppColors.primary : AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(fits ? 'Confirm Setup & Start' : 'Adjust Settings to Confirm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildAdjustment(String title, String desc, VoidCallback onApply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
