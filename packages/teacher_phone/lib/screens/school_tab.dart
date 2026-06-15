import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'shared_drawer.dart';

final curriculumProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(mockDataServiceProvider);
  return service.loadCurriculum();
});

class SchoolTab extends ConsumerStatefulWidget {
  const SchoolTab({Key? key}) : super(key: key);

  @override
  ConsumerState<SchoolTab> createState() => _SchoolTabState();
}

class _SchoolTabState extends ConsumerState<SchoolTab> {
  String? selectedGrade;
  String? selectedSubject;

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(curriculumProvider);
    final lang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(AppStrings.t('school_syllabus', lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary)),
      ),
      body: curriculumAsync.when(
        data: (curriculum) => _buildBody(context, curriculum, lang),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading curriculum: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> fullCurriculum, AppLanguage lang) {
    final grades = fullCurriculum.keys.toList();
    if (grades.isEmpty) return const Center(child: Text('No data'));

    selectedGrade ??= grades.first;
    
    final gradeData = fullCurriculum[selectedGrade] as Map<String, dynamic>? ?? {};
    final subjects = gradeData.keys.toList();
    
    if (!subjects.contains(selectedSubject) && subjects.isNotEmpty) {
      selectedSubject = subjects.first;
    }

    final subjectData = (selectedSubject != null ? gradeData[selectedSubject] : null) as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdown(AppStrings.t('grade', lang), selectedGrade!, grades, (val) {
              if (val != null) setState(() => selectedGrade = val);
            })),
            const SizedBox(width: 16),
            Expanded(child: _buildDropdown(AppStrings.t('subject', lang), selectedSubject ?? '', subjects, (val) {
              if (val != null) setState(() => selectedSubject = val);
            })),
          ],
        ),
        const SizedBox(height: 24),
        
        if (subjectData != null) ...[
          // Premium Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF35A7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subjectData['subject']} Curriculum',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.t('chapter', lang)}: ${subjectData['chapter']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            AppStrings.t('concepts_to_cover', lang),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          
          ...(subjectData['concepts'] as List<dynamic>).map((concept) => _buildConceptCard(concept, lang)).toList(),
        ] else ...[
          const Center(child: Text('No subject selected.')),
        ]
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((i) => DropdownMenuItem(
                value: i, 
                child: Text(i, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary))
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConceptCard(dynamic concept, AppLanguage lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'L${concept['level']}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          title: Text(
            concept['name'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          children: [
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('sample_question', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(concept['sample_question'], style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.t('expected_answer', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(concept['sample_answer'], style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
