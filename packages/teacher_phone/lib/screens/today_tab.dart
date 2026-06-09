import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:go_router/go_router.dart';
import '../providers/planner_state_provider.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerStateProvider);

    if (plannerState == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No Planner Setup Found. Please complete onboarding.')),
      );
    }

    final todayEntries = plannerState.todayEntries;
    final isComplete = plannerState.isTodayComplete;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Session', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.textPrimary)),
      ),
      body: isComplete 
          ? const Center(child: Text('Today\'s Assessments Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success)))
          : _buildBody(context, ref, plannerState, todayEntries),
      floatingActionButton: isComplete ? null : Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ElevatedButton.icon(
          onPressed: () {
            final nextStudent = plannerState.nextStudent;
            if (nextStudent != null) {
              context.push('/assessment');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No more students for today.')));
            }
          },
          icon: const Icon(Icons.cast_connected, color: Colors.white, size: 20),
          label: const Text('Start Smart Board Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, PlannerState state, List<RosterEntry> todayEntries) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (state.nextStudent != null) ...[
          _buildAlertBanner(state.nextStudent!.studentName),
          const SizedBox(height: 16),
        ],
        _buildHeaderCard(state),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Pupil Status Roster', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
            ),
            const Spacer(),
            Text(
              '${todayEntries.length} Total',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...todayEntries.map((student) => _buildStudentCard(context, ref, student)).toList(),
      ],
    );
  }

  Widget _buildAlertBanner(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name needs adaptive assessment help!',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.accent, size: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(PlannerState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF8A7AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ASSESSMENT',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              Text(
                state.currentDay,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Week ${state.currentWeek}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Planner Active Roster',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, WidgetRef ref, RosterEntry student) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (student.status) {
      case RosterStatus.completed:
        statusColor = AppColors.success;
        statusLabel = 'DONE';
        statusIcon = Icons.check_circle_rounded;
        break;
      case RosterStatus.inProgress:
        statusColor = AppColors.primary;
        statusLabel = 'ASSESSING';
        statusIcon = Icons.sensors_rounded;
        break;
      case RosterStatus.absent:
        statusColor = AppColors.accent;
        statusLabel = 'ABSENT';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusLabel = 'PENDING';
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.12),
            child: Text(
              student.studentName.substring(0, 1),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          title: Text(
            student.studentName, 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  '$statusLabel · ${student.subject}', 
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              student.level, 
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 12),
                  const SizedBox(height: 8),
                  if (student.lastQuestion.isNotEmpty) ...[
                    _buildDetailRow('Last Concept Checked:', student.lastQuestion),
                    const SizedBox(height: 6),
                  ],
                  _buildDetailRow('Time Spent in Session:', '${student.timeSpentSeconds} seconds'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref.read(plannerStateProvider.notifier).markStatus(student, RosterStatus.absent);
                        }, 
                        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                        child: const Text('Mark Absent', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/assessment');
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Start Assessment'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
