import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

final reportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(mockDataServiceProvider);
  return service.loadCheckpointReport();
});

class ReportsTab extends ConsumerWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assessment Reports', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report PDF generated & exported!')));
            },
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildBody(context, report),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.accent))),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Milestone Checkpoints', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _buildCheckpointCards(),
        const SizedBox(height: 28),
        
        Row(
          children: [
            Text('Report: ${report['checkpoint']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Text('FINALIZED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        _buildSectionHeader('1. Class Critical Weaknesses'),
        _buildWeaknessesList(report['class_weaknesses']),
        const SizedBox(height: 28),
        
        _buildSectionHeader('2. Incomplete Assessments'),
        _buildIncompleteList(report['incomplete_assessments']),
        const SizedBox(height: 28),
        
        _buildSectionHeader('3. Student Roster Profiles'),
        _buildProfilesList(report['student_profiles']),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)
      ),
    );
  }

  Widget _buildCheckpointCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCPCard('CP1', 'Archived', AppColors.textSecondary, isCompleted: true),
          const SizedBox(width: 12),
          _buildCPCard('CP2', 'Active Report', AppColors.primary, isActive: true),
          const SizedBox(width: 12),
          _buildCPCard('CP3', 'In progress (12d)', AppColors.warning),
          const SizedBox(width: 12),
          _buildCPCard('CP4', 'Locked Milestone', AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildCPCard(String title, String subtitle, Color color, {bool isActive = false, bool isCompleted = false}) {
    final bgColor = isActive 
      ? AppColors.primary.withOpacity(0.08) 
      : (isCompleted ? AppColors.success.withOpacity(0.06) : AppColors.surface);
    final borderColor = isActive 
      ? AppColors.primary 
      : (isCompleted ? AppColors.success : AppColors.primary.withOpacity(0.08));

    return Container(
      width: 144,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: isActive ? 2.2 : 1.5),
        boxShadow: [
          if (isActive)
            BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isActive ? AppColors.primary : (isCompleted ? AppColors.success : AppColors.textPrimary))),
              const Spacer(),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
              if (isActive)
                const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle, 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? AppColors.primary : AppColors.textSecondary)
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessesList(List<dynamic> weaknesses) {
    return Column(
      children: weaknesses.map((w) {
        final percent = (w['below_ideal'] / w['total'] * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(w['subject'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${w['below_ideal']}/${w['total']} Below L3', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(w['status'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: w['below_ideal'] / w['total'],
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.topRight,
                  child: Text('$percent% of class affected', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIncompleteList(List<dynamic> incompletes) {
    return Column(
      children: incompletes.map((i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(i['detail'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfilesList(List<dynamic> studentProfiles) {
    return Column(
      children: studentProfiles.map((student) {
        Color statusColor;
        switch (student['status']) {
          case 'Ahead': statusColor = AppColors.success; break;
          case 'On track': statusColor = AppColors.primary; break;
          case 'Behind': statusColor = AppColors.accent; break;
          default: statusColor = AppColors.textSecondary;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withOpacity(0.1),
                child: Text(
                  student['name'].substring(0, 1),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(student['status'], style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // mini levels matrix text
                    Text(
                      'Math: L${student['levels']['Mathematics']} · Sci: L${student['levels']['Science']} · Lang: L${student['levels']['Language']} · Soc: L${student['levels']['Social Studies']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
