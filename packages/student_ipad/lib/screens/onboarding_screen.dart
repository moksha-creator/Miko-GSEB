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

  int _currentStep = 0;
  final int _totalSteps = 7;

  bool _isManualRoster = false;
  final TextEditingController _pasteController = TextEditingController();

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
        lectureLength: 40,
        sessionsPerWeek: 2,
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
    setState(() => draft = newDraft);
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (context.canPop()) context.pop();
    }
  }

  void _confirm() async {
    await ref.read(classSetupProvider.notifier).save(draft);
    if (!mounted) return;
    context.go('/');
  }

  String _getCheckpointName() {
    if (draft.checkpoint == 'monthly') return 'end of month';
    if (draft.checkpoint == 'quarterly') return 'end of term';
    return 'end of year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 800;
            Widget rail = _buildStepRail();
            Widget content = Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStepContent(key: ValueKey(_currentStep)),
                  ),
                ),
                if (_currentStep >= 3 && _currentStep < 6) _buildCompactPlanFooter(),
                _buildBottomNavigation(),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(right: BorderSide(color: AppColors.primary.withOpacity(0.1))),
                    ),
                    child: rail,
                  ),
                  Expanded(child: content),
                ],
              );
            } else {
              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _buildHorizontalProgress(),
                  ),
                  Expanded(child: content),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildStepRail() {
    final steps = [
      'Welcome', 'Class', 'Students', 'Subjects', 'Schedule', 'Deadline', 'Review'
    ];
    final summaries = [
      '', 
      'Grade ${draft.grade} - ${draft.section}', 
      '${draft.studentCount} students', 
      '${draft.activeSubjects.length} subjects',
      draft.assessmentMode == 'ded' ? '${draft.sessionsPerWeek} sessions/wk' : 'Embedded',
      _getCheckpointName(),
      ''
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _totalSteps,
      itemBuilder: (context, i) {
        bool isActive = i == _currentStep;
        bool isDone = i < _currentStep;
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.primary : (isDone ? AppColors.success : Colors.grey.shade200),
                ),
                alignment: Alignment.center,
                child: isDone 
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${i+1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(steps[i], style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.primary : (isDone ? AppColors.textPrimary : Colors.grey.shade500),
                      fontSize: 16,
                    )),
                    if (isDone && summaries[i].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(summaries[i], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          bool isDoneOrActive = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isDoneOrActive ? AppColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent({required Key key}) {
    switch (_currentStep) {
      case 0: return _stepWelcome();
      case 1: return _stepClass();
      case 2: return _stepStudents();
      case 3: return _stepSubjects();
      case 4: return _stepSchedule();
      case 5: return _stepDeadline();
      case 6: return _stepReview();
      default: return const SizedBox();
    }
  }

  Widget _buildBottomNavigation() {
    bool isLast = _currentStep == _totalSteps - 1;
    bool fits = _planner.isFeasible(draft);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _back,
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            )
          else 
            const SizedBox(width: 64),
            
          const Spacer(),
          
          if (!isLast)
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            )
          else
            ElevatedButton(
              onPressed: fits ? _confirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: fits ? AppColors.success : AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm & Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _wrapStep(String title, String subtitle, Widget child) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 48),
        child,
      ],
    );
  }

  Widget _stepWelcome() {
    return _wrapStep(
      'Welcome to Miko Smart Board',
      'The easiest way to run continuous assessments for your entire class. This wizard will ask a few simple questions to build your schedule.\n\nIt takes about 2 minutes.',
      const Center(child: Icon(Icons.school, size: 120, color: AppColors.primary)),
    );
  }

  Widget _stepClass() {
    return _wrapStep(
      'Your class',
      'Which grade and division are you setting up?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.1))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: draft.grade,
                items: List.generate(10, (i) => DropdownMenuItem(value: '${i+1}', child: Text('Grade ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)))),
                onChanged: (v) => _updateDraft(draft.copyWith(grade: v!)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Division', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: ['A', 'B', 'C', 'D', 'E'].map((div) {
              bool sel = draft.section == div;
              return ChoiceChip(
                label: Text('Div $div', style: TextStyle(fontSize: 16, color: sel ? Colors.white : AppColors.textPrimary)),
                selected: sel,
                onSelected: (v) { if (v) _updateDraft(draft.copyWith(section: div)); },
                selectedColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              );
            }).toList(),
          ),
        ],
      )
    );
  }

  Widget _stepStudents() {
    return _wrapStep(
      'Add students',
      'How many students are in this class?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isManualRoster = false;
                      _updateDraft(draft.copyWith(studentCount: 40, studentNames: null));
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: !_isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                      border: Border.all(color: !_isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_download, color: AppColors.primary, size: 32),
                        const SizedBox(height: 12),
                        Text('Import from MIS\n(${!_isManualRoster ? 40 : draft.studentCount} students)', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isManualRoster = true;
                      _onPastedNamesChanged();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isManualRoster ? AppColors.primary.withOpacity(0.08) : Colors.white,
                      border: Border.all(color: _isManualRoster ? AppColors.primary : AppColors.primary.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.content_paste, color: AppColors.primary, size: 32),
                        SizedBox(height: 12),
                        Text('Paste Names\n(One per line)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isManualRoster) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _pasteController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'John Doe\nJane Smith\n...',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Total: ${draft.studentCount} students detected', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ],
      )
    );
  }

  Widget _stepSubjects() {
    return _wrapStep(
      'Choose subjects',
      'Which subjects do you want to assess?',
      Column(
        children: _allSubjects.map((sub) {
          bool sel = draft.activeSubjects.contains(sub['id']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? sub['c'] : Colors.grey.shade300, width: sel ? 2 : 1),
            ),
            child: CheckboxListTile(
              title: Text(sub['name'], style: TextStyle(fontWeight: FontWeight.bold, color: sel ? sub['c'] : AppColors.textPrimary)),
              value: sel,
              activeColor: sub['c'],
              onChanged: (v) {
                var newList = List<String>.from(draft.activeSubjects);
                if (v == true) newList.add(sub['id']);
                else if (newList.length > 1) newList.remove(sub['id']);
                _updateDraft(draft.copyWith(activeSubjects: newList));
              },
            ),
          );
        }).toList(),
      )
    );
  }

  Widget _stepSchedule() {
    return _wrapStep(
      'When you\'ll run it',
      'How do you plan to schedule the assessments?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  'Separate Slot', 'I have a dedicated period for Miko assessments.', 'ded'
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeCard(
                  'Inside a Lecture', 'I will run it during regular subject periods.', 'emb'
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          const Text('Period Length', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('How long is one period?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [30, 35, 40, 45].map((len) {
              bool sel = draft.lectureLength == len;
              return ChoiceChip(
                label: Text('$len min', style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary)),
                selected: sel,
                onSelected: (v) { if (v) _updateDraft(draft.copyWith(lectureLength: len)); },
                selectedColor: AppColors.primary,
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          if (draft.assessmentMode == 'ded') ...[
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('How many times a week will this class have a Miko slot?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: draft.sessionsPerWeek > 1 ? () => _updateDraft(draft.copyWith(sessionsPerWeek: draft.sessionsPerWeek - 1)) : null,
                ),
                Text('${draft.sessionsPerWeek} times / week', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: draft.sessionsPerWeek < 10 ? () => _updateDraft(draft.copyWith(sessionsPerWeek: draft.sessionsPerWeek + 1)) : null,
                ),
              ],
            )
          ] else ...[
            const Text('Lectures per week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...draft.activeSubjects.map((subId) {
              final sub = _allSubjects.firstWhere((s) => s['id'] == subId, orElse: () => {'id': subId, 'name': subId, 'c': Colors.grey});
              final val = draft.subjectLecturesPerWeek[subId] ?? 4;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(
                      child: Slider(
                        value: val.toDouble(), min: 1, max: 10, divisions: 9,
                        activeColor: sub['c'],
                        onChanged: (v) {
                          var map = Map<String, int>.from(draft.subjectLecturesPerWeek);
                          map[subId] = v.round();
                          _updateDraft(draft.copyWith(subjectLecturesPerWeek: map));
                        },
                      ),
                    ),
                    Text('$val/wk', style: TextStyle(fontWeight: FontWeight.bold, color: sub['c'])),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      )
    );
  }

  Widget _buildModeCard(String title, String desc, String mode) {
    bool sel = draft.assessmentMode == mode;
    return InkWell(
      onTap: () => _updateDraft(draft.copyWith(assessmentMode: mode)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.08) : Colors.white,
          border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(mode == 'ded' ? Icons.event_available : Icons.dashboard_customize, color: sel ? AppColors.primary : Colors.grey, size: 32),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _stepDeadline() {
    return _wrapStep(
      'Set the deadline',
      'By when must every student finish a full round of assessments?',
      Column(
        children: [
          _buildCheckpointCard('End of Month', '~4 weeks', 'monthly'),
          _buildCheckpointCard('End of Term', '~13 weeks', 'quarterly'),
          _buildCheckpointCard('End of Year', '~40 weeks', 'yearly'),
        ],
      )
    );
  }

  Widget _buildCheckpointCard(String title, String subtitle, String cp) {
    bool sel = draft.checkpoint == cp;
    return InkWell(
      onTap: () => _updateDraft(draft.copyWith(checkpoint: cp)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary.withOpacity(0.08) : Colors.white,
          border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade300, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _stepReview() {
    bool fits = _planner.isFeasible(draft);
    int throughput = _planner.calculateThroughput(draft);
    
    // Calculate breakdown
    List<Widget> rows = [];
    if (draft.assessmentMode == 'ded') {
      int weeksPerSub = (draft.studentCount / throughput).ceil();
      int startWk = 1;
      for (var subId in draft.activeSubjects) {
        String subName = _allSubjects.firstWhere((s) => s['id'] == subId, orElse: () => {'id': subId, 'name': subId, 'c': Colors.grey})['name'];
        int endWk = startWk + weeksPerSub - 1;
        String wStr = startWk == endWk ? 'wk $startWk' : 'wks $startWk-$endWk';
        rows.add(_buildBreakdownRow(subName, '${draft.studentCount}', wStr));
        startWk += weeksPerSub;
      }
    } else {
      for (var subId in draft.activeSubjects) {
        String subName = _allSubjects.firstWhere((s) => s['id'] == subId, orElse: () => {'id': subId, 'name': subId, 'c': Colors.grey})['name'];
        int tp = _planner.calculateThroughput(draft, subjectId: subId);
        int wps = (draft.studentCount / tp).ceil();
        rows.add(_buildBreakdownRow(subName, '${draft.studentCount}', 'wks 1-$wps'));
      }
    }

    String summaryLine = '';
    if (draft.assessmentMode == 'ded') {
      summaryLine = "About $throughput students a week. All subjects finish by ${_getCheckpointName()}.";
    } else {
      summaryLine = "Running in parallel. All subjects finish by ${_getCheckpointName()}.";
    }

    return _wrapStep(
      'Review & Confirm',
      'Here is the plan you\'ve built.',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summaryLine, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                if (draft.assessmentMode == 'ded') ...[
                  const SizedBox(height: 8),
                  Text("~${throughput} students each week · ${(draft.lectureLength/5).floor()} per session × ${draft.sessionsPerWeek} sessions", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(flex: 2, child: Text('SUBJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 1, child: Text('STUDENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 1, child: Text('WEEKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
                const Divider(),
                ...rows,
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildFitsCard(fits),
        ],
      )
    );
  }

  Widget _buildBreakdownRow(String sub, String students, String weeks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 1, child: Text(students, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(flex: 1, child: Text(weeks, style: const TextStyle(color: AppColors.primary))),
        ],
      ),
    );
  }

  Widget _buildFitsCard(bool fits) {
    if (fits) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Fits ${_getCheckpointName()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 16)),
        ],
      );
    } else {
      String fixText = '';
      VoidCallback? fixAction;
      
      if (draft.assessmentMode == 'ded' && draft.sessionsPerWeek < 5) {
        fixText = 'Run it ${draft.sessionsPerWeek + 1}× a week';
        fixAction = () => _updateDraft(draft.copyWith(sessionsPerWeek: draft.sessionsPerWeek + 1));
      } else if (draft.checkpoint == 'monthly') {
        fixText = 'Give it till end of term';
        fixAction = () => _updateDraft(draft.copyWith(checkpoint: 'quarterly'));
      } else if (draft.checkpoint == 'quarterly') {
        fixText = 'Give it till end of year';
        fixAction = () => _updateDraft(draft.copyWith(checkpoint: 'yearly'));
      } else if (draft.activeSubjects.length > 1) {
        fixText = 'Assess fewer subjects';
        fixAction = () {
          var s = List<String>.from(draft.activeSubjects);
          s.removeLast();
          _updateDraft(draft.copyWith(activeSubjects: s));
        };
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Does not fit ${_getCheckpointName()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Suggested fix: $fixText', style: const TextStyle(fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: fixAction,
                  child: const Text('Apply Fix', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      );
    }
  }

  Widget _buildCompactPlanFooter() {
    bool fits = _planner.isFeasible(draft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          const Text('Plan so far: ', style: TextStyle(color: Colors.grey)),
          Text('${draft.activeSubjects.length} subjects · ${draft.studentCount} students', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(fits ? Icons.check_circle : Icons.warning, color: fits ? AppColors.success : AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(fits ? 'Fits' : 'Too tight', style: TextStyle(color: fits ? AppColors.success : AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
