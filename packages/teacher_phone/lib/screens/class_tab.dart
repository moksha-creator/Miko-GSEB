import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'shared_drawer.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

final classSampleProvider = FutureProvider<ClassProfile>((ref) async {
  final service = ref.watch(mockDataServiceProvider);
  return service.loadClassSample();
});

class ClassTab extends ConsumerStatefulWidget {
  const ClassTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ClassTab> createState() => _ClassTabState();
}

class _ClassTabState extends ConsumerState<ClassTab> {
  Timer? _syncTimer;
  String _lastSetupStr = "";

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        try {
          final hasSetup = js.context.hasProperty('localStorage') && js.context['localStorage'].hasProperty('getItem');
          if (hasSetup) {
            final setupStr = js.context['localStorage'].callMethod('getItem', ['miko_class_setup']) ?? "";
            if (setupStr != _lastSetupStr) {
              _lastSetupStr = setupStr;
              ref.invalidate(classSampleProvider);
            }
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(classSampleProvider);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Classroom Roster', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary)),
      ),
      body: classAsync.when(
        data: (profile) => _buildBody(context, profile, lang),
        loading: () => _buildLoader(),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.accent))),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text('📋', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Loading class data…', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const SizedBox(width: 120, child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.primaryLight)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ClassProfile profile, AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(profile),
        const SizedBox(height: 24),
        Row(
          children: const [
            Text(
              'Progression Board', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
            ),
            Spacer(),
            Icon(Icons.filter_list_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        _buildMatrixCardsList(context, profile, lang),
      ],
    );
  }

  Widget _buildSummaryCard(ClassProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.06), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryMetric('${profile.students.length}', 'Students', AppColors.primary),
          _buildVerticalDivider(),
          _buildSummaryMetric('L2.4', 'Avg Level', AppColors.success),
          _buildVerticalDivider(),
          _buildSummaryMetric('92%', 'Completion', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.primary.withOpacity(0.12),
    );
  }

  Widget _buildSummaryMetric(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMatrixCardsList(BuildContext context, ClassProfile profile, AppLanguage lang) {
    return Column(
      children: profile.students.map((student) {
        final avatarColor = _colorFromHex(student.avatarColor);
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
          child: InkWell(
            onTap: () => _showStudentDetailBottomSheet(context, student),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor.withOpacity(0.12),
                    child: Text(
                      AppStrings.t(student.name, lang).substring(0, 1),
                      style: TextStyle(color: avatarColor, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.t(student.name, lang), 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)
                        ),
                        const SizedBox(height: 6),
                        // Levels Row
                        Row(
                          children: [
                            _buildSubjectPill('M', student.currentLevels['Mathematics']),
                            const SizedBox(width: 4),
                            _buildSubjectPill('S', student.currentLevels['Science']),
                            const SizedBox(width: 4),
                            _buildSubjectPill('L', student.currentLevels['Language']),
                            const SizedBox(width: 4),
                            _buildSubjectPill('SS', student.currentLevels['Social Studies']),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectPill(String subAbbr, int? level) {
    if (level == null) return const SizedBox.shrink();
    Color pillColor;
    switch (level) {
      case 1: pillColor = AppColors.level1; break;
      case 2: pillColor = AppColors.level2; break;
      case 3: pillColor = AppColors.level3; break;
      case 4: pillColor = AppColors.level4; break;
      default: pillColor = AppColors.surface;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$subAbbr: L$level',
        style: TextStyle(
          color: level > 2 ? Colors.white : AppColors.textPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _showStudentDetailBottomSheet(BuildContext context, Student student) {
    final avatarColor = _colorFromHex(student.avatarColor);
    final lang = ref.read(localeProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: avatarColor.withOpacity(0.15),
                    child: Text(
                      AppStrings.t(student.name, lang).substring(0, 1),
                      style: TextStyle(color: avatarColor, fontWeight: FontWeight.w900, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t(student.name, lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('Grade 5-B · Roll No: #${student.rollNo}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Mastery Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildBottomSheetProgressRow('Mathematics', student.currentLevels['Mathematics'] ?? 1),
              _buildBottomSheetProgressRow('Science', student.currentLevels['Science'] ?? 1),
              _buildBottomSheetProgressRow('Language', student.currentLevels['Language'] ?? 1),
              _buildBottomSheetProgressRow('Social Studies', student.currentLevels['Social Studies'] ?? 1),
              
              const SizedBox(height: 24),
              
              // Warning box if stuck
              if (student.flaggedConcepts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flagged Concept: ${student.flaggedConcepts.first.concept}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              student.flaggedConcepts.first.note,
                              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Remote assessment requested on iPad for ${AppStrings.t(student.name, lang).split(' ')[0]}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.tablet_android_rounded, color: Colors.white, size: 20),
                label: const Text('Queue iPad remote assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetProgressRow(String subject, int level) {
    Color color;
    switch (level) {
      case 1: color = AppColors.accent; break;
      case 2: color = Colors.orange; break;
      case 3: color = AppColors.primary; break;
      case 4: color = AppColors.success; break;
      default: color = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(subject, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: level / 4.0,
                      backgroundColor: AppColors.background,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('L$level', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
