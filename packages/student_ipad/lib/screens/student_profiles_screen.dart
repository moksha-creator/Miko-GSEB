import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_core/shared_core.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import '../providers/planner_state_provider.dart';

// Provider to hold the currently selected student for assessment
class SelectedStudentNotifier extends Notifier<Student?> {
  @override
  Student? build() => null;

  void select(Student? student) {
    state = student;
  }
}

final selectedStudentProvider = NotifierProvider<SelectedStudentNotifier, Student?>(SelectedStudentNotifier.new);

// Provider to fetch the mock students
final classRosterProvider = FutureProvider<ClassProfile>((ref) async {
  final service = ref.watch(mockDataServiceProvider);
  return service.loadClassSample();
});

// (Old completion and skipped providers removed in favor of CoverageService)

// Language Provider
class IsGujaratiNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() {
    state = !state;
    ref.read(localeProvider.notifier).setLocale(state ? AppLanguage.gujarati : AppLanguage.english);
  }
}
final isGujaratiProvider = NotifierProvider<IsGujaratiNotifier, bool>(IsGujaratiNotifier.new);

// Translations
String _t(String key, bool isGuj) {
  return AppStrings.t(key, isGuj ? AppLanguage.gujarati : AppLanguage.english);
}

String _getAvatarAsset(String id) {
  final avatars = ['aarav', 'ananya', 'arjun', 'dev', 'diya', 'kavya', 'krish', 'mira', 'priya', 'rohan'];
  final idx = id.hashCode % avatars.length;
  return 'assets/avatars/${avatars[idx.abs()]}.png';
}


// Provider to track selected subject
class SelectedSubjectNotifier extends Notifier<String> {
  @override
  String build() => 'Mathematics';

  void setSubject(String subject) {
    state = subject;
  }
}

final selectedSubjectProvider = NotifierProvider<SelectedSubjectNotifier, String>(SelectedSubjectNotifier.new);

// Provider to track added students
class AddedStudentsNotifier extends Notifier<List<Student>> {
  @override
  List<Student> build() => [];

  void addStudent(Student student) {
    state = [...state, student];
  }

  void clear() {
    state = [];
  }
}

final addedStudentsProvider = NotifierProvider<AddedStudentsNotifier, List<Student>>(AddedStudentsNotifier.new);

// Combined provider of roster students and dynamic additions
final allStudentsProvider = Provider<List<Student>>((ref) {
  final rosterAsync = ref.watch(classRosterProvider);
  final added = ref.watch(addedStudentsProvider);
  return rosterAsync.when(
    data: (profile) => [...profile.students, ...added],
    loading: () => added,
    error: (_, __) => added,
  );
});

class StudentProfilesScreen extends ConsumerStatefulWidget {
  const StudentProfilesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentProfilesScreen> createState() => _StudentProfilesScreenState();
}

class _StudentProfilesScreenState extends ConsumerState<StudentProfilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSubject();
    });
  }

  void _initSubject() {
    final setup = ref.read(classSetupProvider);
    final currentSub = ref.read(selectedSubjectProvider);
    if (setup != null && setup.activeSubjects.isNotEmpty) {
      if (!setup.activeSubjects.contains(currentSub)) {
        ref.read(selectedSubjectProvider.notifier).setSubject(setup.activeSubjects.first);
      }
    } else if (setup == null && currentSub.isEmpty) {
      ref.read(selectedSubjectProvider.notifier).setSubject('math');
    }
  }

  void _showPasswordDialog(BuildContext context, VoidCallback onSuccess) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enter Teacher Password', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: tc,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Password is "1234"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (tc.text == '1234') {
                context.pop();
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password')));
              }
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    _showPasswordDialog(context, () {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Teacher Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.analytics, color: AppColors.primary),
                  title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: AppColors.surface,
                  onTap: () {
                    context.pop();
                    context.push('/reports');
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.red),
                  title: const Text('Reset Data & Schedule', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Colors.red.withOpacity(0.05),
                  onTap: () {
                    context.pop();
                    ref.read(classSetupProvider.notifier).reset();
                    ref.read(plannerStateProvider.notifier).reset();
                    ref.read(addedStudentsProvider.notifier).clear();
                    context.go('/setup');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showSubjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change Subject', style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubjectTile('math', 'Mathematics'),
              
              _buildSubjectTile('eng', 'English'),
              _buildSubjectTile('guj', 'Gujarati'),
              
              
              _buildSubjectTile('evs', 'EVS'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            )
          ],
        );
      }
    );
  }

  Widget _buildSubjectTile(String id, String name) {
    final current = ref.watch(selectedSubjectProvider);
    return ListTile(
      title: Text(name),
      trailing: current == id ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(selectedSubjectProvider.notifier).setSubject(id);
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuj = ref.watch(isGujaratiProvider);
    final subject = ref.watch(selectedSubjectProvider);
    final rosterAsync = ref.watch(classRosterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Text(_t('grade_5_b', isGuj), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  InkWell(
                    onTap: _showSubjectDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(_t(subject, isGuj).toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ref.read(isGujaratiProvider.notifier).toggle(),
                    icon: const Icon(Icons.language, color: AppColors.textSecondary),
                    label: Text(isGuj ? 'EN' : 'ગુ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 28),
                    onPressed: _showSettingsMenu,
                  ),
                ],
              ),
            ),
            
            // CONTENT
            Expanded(
              child: rosterAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (profile) {
                  final allStudents = ref.watch(allStudentsProvider);
                  final coverageService = ref.watch(coverageServiceProvider);
                  final setup = ref.watch(classSetupProvider);
                  final currentCheckpointId = setup?.checkpoint ?? 'monthly';
                  
                  // Auto-select next student using CoverageService
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentlySelected = ref.read(selectedStudentProvider);
                    final next = coverageService.assignNext(
                      eligible: allStudents,
                      subjectId: subject,
                      checkpointId: currentCheckpointId,
                      now: DateTime.now(),
                    );
                    
                    if (currentlySelected?.id != next?.id) {
                      ref.read(selectedStudentProvider.notifier).select(next);
                    }
                  });

                  final activeStudent = ref.watch(selectedStudentProvider);
                  
                  // For the UI counters
                  final coveredCount = coverageService.getCoveredCount(subject, currentCheckpointId, allStudents);
                  final absentCount = coverageService.getAbsentCount(subject, currentCheckpointId, allStudents);
                  final pendingCount = allStudents.length - coveredCount - absentCount;
                  
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UP NEXT CARD
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: activeStudent == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 80, color: AppColors.success),
                                    SizedBox(height: 24),
                                    Text('Checkpoint Complete', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Text('All covered — switch subject or finish.', style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_t('up_next', isGuj).toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 2)),
                                  const SizedBox(height: 32),
                                  Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      activeStudent?.name.isNotEmpty == true ? activeStudent!.name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(_t(activeStudent?.name ?? '', isGuj), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Text('${_t('roll_no', isGuj)}: ${activeStudent?.rollNo} · ${_t(subject, isGuj)}', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                                  const SizedBox(height: 48),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () {
                                              if (activeStudent != null) {
                                                ref.read(coverageServiceProvider).markAbsentToday(
                                                  activeStudent.id,
                                                  ref.read(classSetupProvider)?.checkpoint ?? 'monthly',
                                                  ref.read(selectedSubjectProvider),
                                                );
                                                // Trigger rebuild
                                                ref.read(selectedStudentProvider.notifier).select(null);
                                              }
                                          },
                                          icon: const Icon(Icons.person_off),
                                          label: Text(_t('mark_absent', isGuj), style: const TextStyle(fontSize: 16)),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.accent,
                                            padding: const EdgeInsets.symmetric(vertical: 24),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () => context.go('/be-ready'),
                                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                                          label: Text(_t('start_session', isGuj), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 24),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                        ),
                      ),
                      
                      // ROSTER LIST
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.only(top: 24, bottom: 24, right: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(_t('todays_roster', isGuj), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        Text('$coveredCount ${_t('done', isGuj).toLowerCase()} · $absentCount ${_t('absent', isGuj).toLowerCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Row(
                                        children: [
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: coveredCount > 0 ? coveredCount : 1,
                                              child: Container(height: 8, color: coveredCount > 0 ? AppColors.success : Colors.transparent),
                                            ),
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: absentCount > 0 ? absentCount : 1,
                                              child: Container(height: 8, color: absentCount > 0 ? AppColors.accent : Colors.transparent),
                                            ),
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: pendingCount > 0 ? pendingCount : 1,
                                              child: Container(height: 8, color: pendingCount > 0 ? Colors.grey.shade200 : Colors.transparent),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: allStudents.length,
                                  itemBuilder: (context, i) {
                                    final st = allStudents[i];
                                    final currentCheckpointId = ref.read(classSetupProvider)?.checkpoint ?? 'monthly';
                                    final status = ref.read(coverageServiceProvider).getStudentStatus(st.id, currentCheckpointId, subject);
                                    
                                    final isDone = status == 'covered';
                                    final isSkipped = status == 'absentToday';
                                    final isNext = activeStudent?.id == st.id;
                                    
                                    Color textColor = isDone ? Colors.grey.shade400 : (isSkipped ? AppColors.accent.withOpacity(0.5) : AppColors.textPrimary);
                                    
                                    return Container(
                                      color: isNext ? AppColors.primary.withOpacity(0.05) : null,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                        leading: CircleAvatar(
                                          backgroundColor: isNext ? AppColors.primary : Colors.grey.shade200,
                                          foregroundColor: isNext ? Colors.white : Colors.grey.shade600,
                                          child: Text(st.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        title: Text(_t(st.name, isGuj), style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal, color: textColor)),
                                        subtitle: Text('${_t('roll_no', isGuj)}: ${st.rollNo}', style: TextStyle(color: textColor.withOpacity(0.7))),
                                        trailing: isDone 
                                          ? const Icon(Icons.check_circle, color: AppColors.success)
                                          : (isSkipped ? const Icon(Icons.remove_circle, color: AppColors.accent) : null),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // INSTRUCTION FOOTER
            Container(
              child: Text(
                _t('call_child_to_board', isGuj),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
