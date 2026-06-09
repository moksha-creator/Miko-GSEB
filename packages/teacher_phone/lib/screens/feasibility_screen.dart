import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_state_provider.dart';

class FeasibilityScreen extends ConsumerStatefulWidget {
  final ClassSetup initialSetup;
  const FeasibilityScreen({Key? key, required this.initialSetup}) : super(key: key);

  @override
  ConsumerState<FeasibilityScreen> createState() => _FeasibilityScreenState();
}

class _FeasibilityScreenState extends ConsumerState<FeasibilityScreen> {
  late ClassSetup currentSetup;
  final PlannerService _planner = PlannerService();

  @override
  void initState() {
    super.initState();
    currentSetup = widget.initialSetup;
  }

  void _applyFix(ClassSetup newSetup) {
    setState(() {
      currentSetup = newSetup;
    });
  }

  void _confirm() async {
    await ref.read(classSetupProvider.notifier).save(currentSetup);
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Classroom Session Updated!', 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text('Your assessment schedule has been successfully generated and is ready to go.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home', extra: true);
                  final plannerState = ref.read(plannerStateProvider);
                  final nextStudent = plannerState?.nextStudent;
                  if (nextStudent != null) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) context.push('/assessment');
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start Smart Board Session', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int throughput = 0;
    int weeksNeeded = _planner.calculateWeeksNeeded(currentSetup);
    bool fits = _planner.isFeasible(currentSetup);
    int window = currentSetup.checkpointWindowWeeks;
    int totalTime = currentSetup.studentCount * currentSetup.activeSubjects.length * 5;
    
    String? bottleneckSubjectId = _planner.getBottleneckSubject(currentSetup);
    String bottleneckName = '';
    if (bottleneckSubjectId != null) {
      switch (bottleneckSubjectId) {
        case 'math': bottleneckName = 'Mathematics'; break;
        case 'sci': bottleneckName = 'Science'; break;
        case 'lang': bottleneckName = 'Language'; break;
        case 'soc': bottleneckName = 'Social Studies'; break;
        default: bottleneckName = bottleneckSubjectId;
      }
    } else {
      throughput = _planner.calculateThroughput(currentSetup);
    }

    final verdictColor = fits ? AppColors.success : AppColors.accent;
    final verdictTitle = fits ? 'GOAL IS REACHABLE' : 'GOAL IS NOT REACHABLE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Feasibility Check', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
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
                          fits ? 'Every student can finish all ${currentSetup.activeSubjects.length} subjects before the $window-week deadline.'
                               : (bottleneckSubjectId != null 
                                    ? '$bottleneckName is your bottleneck, requiring $weeksNeeded weeks. Your checkpoint is in $window weeks.'
                                    : 'It will take $weeksNeeded weeks to assess everyone, but the checkpoint is in $window weeks.'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
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

                  const Text('Throughput & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (currentSetup.assessmentMode == 'ded')
                    _buildDetailRow('Students per week', '$throughput', 'Derived from your assessment slot')
                  else ...currentSetup.activeSubjects.map((subId) {
                    int subTp = _planner.calculateThroughput(currentSetup, subjectId: subId);
                    String subName = '';
                    switch (subId) {
                      case 'math': subName = 'Mathematics'; break;
                      case 'sci': subName = 'Science'; break;
                      case 'lang': subName = 'Language'; break;
                      case 'soc': subName = 'Social Studies'; break;
                      default: subName = subId;
                    }
                    return _buildDetailRow('$subName Throughput', '$subTp/wk', 'Parallel embedded assessments');
                  }),
                  _buildDetailRow('Total assessment time', '$totalTime min', 'For one full round of the class'),
                  const SizedBox(height: 32),

                  if (!fits) ...[
                    const Text('Suggested Adjustments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    
                    if (currentSetup.assessmentMode == 'emb')
                      _buildAdjustment(
                        'Switch to Dedicated Slot', 
                        'Increases global throughput to ${(currentSetup.schoolDays - 1) * 10}/week.',
                        () => _applyFix(currentSetup.copyWith(assessmentMode: 'ded')),
                      )
                    else if (currentSetup.schoolDays == 5)
                      _buildAdjustment(
                        'Switch to 6-day week', 
                        'Increases throughput to 50/week.',
                        () => _applyFix(currentSetup.copyWith(schoolDays: 6)),
                      ),
                      
                    if (currentSetup.checkpoint == 'monthly')
                      _buildAdjustment(
                        'Extend Checkpoint to Quarterly', 
                        'Gives you 13 weeks instead of 4.',
                        () => _applyFix(currentSetup.copyWith(checkpoint: 'quarterly')),
                      )
                    else if (currentSetup.checkpoint == 'quarterly')
                      _buildAdjustment(
                        'Extend Checkpoint to Yearly', 
                        'Gives you 40 weeks instead of 13.',
                        () => _applyFix(currentSetup.copyWith(checkpoint: 'yearly')),
                      ),
                      
                    if (currentSetup.activeSubjects.length > 1)
                      _buildAdjustment(
                        bottleneckSubjectId != null ? 'Drop $bottleneckName' : 'Assess Fewer Subjects', 
                        'Save ${currentSetup.studentCount * 5} min/round.',
                        () {
                          var newSubjects = List<String>.from(currentSetup.activeSubjects);
                          if (bottleneckSubjectId != null && newSubjects.contains(bottleneckSubjectId)) {
                            newSubjects.remove(bottleneckSubjectId);
                          } else {
                            newSubjects.removeLast();
                          }
                          _applyFix(currentSetup.copyWith(activeSubjects: newSubjects));
                        },
                      ),
                      
                    if (currentSetup.assessmentMode == 'emb' && bottleneckSubjectId != null)
                      if ((currentSetup.subjectLecturesPerWeek[bottleneckSubjectId] ?? 0) < 10)
                        _buildAdjustment(
                          'Embed More $bottleneckName Lectures', 
                          'Add 1 more lecture per week to break the bottleneck.',
                          () {
                            var newMap = Map<String, int>.from(currentSetup.subjectLecturesPerWeek);
                            newMap[bottleneckSubjectId] = (newMap[bottleneckSubjectId] ?? 4) + 1;
                            _applyFix(currentSetup.copyWith(subjectLecturesPerWeek: newMap));
                          },
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
                  onPressed: fits ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fits ? AppColors.primary : AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(fits ? 'Confirm Setup & Start' : 'Adjust Settings to Confirm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildAdjustment(String title, String desc, VoidCallback onApply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
