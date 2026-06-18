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

// Provider to track completed student IDs
class CompletedStudentsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markCompleted(String studentId) {
    state = {...state}..add(studentId);
  }
  
  void clear() {
    state = {};
  }
}

final completedStudentsProvider = NotifierProvider<CompletedStudentsNotifier, Set<String>>(CompletedStudentsNotifier.new);

// Provider to track skipped student IDs
class SkippedStudentsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void skip(String studentId) {
    state = {...state}..add(studentId);
  }

  void unskip(String studentId) {
    state = {...state}..remove(studentId);
  }

  void clear() {
    state = {};
  }
}


final skippedStudentsProvider = NotifierProvider<SkippedStudentsNotifier, Set<String>>(SkippedStudentsNotifier.new);

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
String _t(String en, bool isGuj) {
  if (!isGuj) return en;
  final map = {
    'Good Morning, Teacher!': 'શુભ સવાર, શિક્ષક!',
    "Here's your assessment dashboard for today.": 'અહીં તમારું આજના મૂલ્યાંકન ડેશબોર્ડ છે.',
    'Now Assessing': 'હવે મૂલ્યાંકન થઈ રહ્યું છે',
    'Start Assessment': 'મૂલ્યાંકન શરૂ કરો',
    "Today's Session": 'આજનું સત્ર',
    'Skipped Today': 'આજે છોડેલા',
    "Don't worry!": 'ચિંતા કરશો નહીં!',
    'They can try again tomorrow': 'તેઓ આવતીકાલે ફરી પ્રયાસ કરી શકે છે',
    'No skipped children!': 'કોઈ બાળક છોડવામાં આવ્યું નથી!',
    'All Active Students Evaluated!': 'બધા સક્રિય વિદ્યાર્થીઓનું મૂલ્યાંકન પૂર્ણ થયું!',
    'Skip': 'છોડો',
    'Roll No.': 'રોલ નં.',
  };
  return map[en] ?? en;
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
        ref.read(selectedSubjectProvider.notifier).select(setup.activeSubjects.first);
      }
    } else if (setup == null && currentSub.isEmpty) {
      ref.read(selectedSubjectProvider.notifier).select('math');
    }
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
              _buildSubjectTile('sci', 'Science'),
              _buildSubjectTile('eng', 'English'),
              _buildSubjectTile('guj', 'Gujarati'),
              _buildSubjectTile('lang', 'Language'),
              _buildSubjectTile('soc', 'Social Studies'),
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
        ref.read(selectedSubjectProvider.notifier).select(id);
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
                  const Text('Grade 5 B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                          Text(_t(subject.toUpperCase(), isGuj), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                  ElevatedButton.icon(
                    onPressed: () => context.push('/reports'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Reports'),
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
                  final completed = ref.watch(completedStudentsProvider);
                  final skipped = ref.watch(skippedStudentsProvider);
                  
                  // Pending queue
                  final pending = allStudents.where((s) => !completed.contains(s.id) && !skipped.contains(s.id)).toList();
                  
                  // Auto-select top student
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentlySelected = ref.read(selectedStudentProvider);
                    if (pending.isNotEmpty && (currentlySelected == null || !pending.any((s) => s.id == currentlySelected.id))) {
                      ref.read(selectedStudentProvider.notifier).select(pending.first);
                    } else if (pending.isEmpty && currentlySelected != null) {
                      ref.read(selectedStudentProvider.notifier).select(null);
                    }
                  });

                  final activeStudent = ref.watch(selectedStudentProvider);
                  
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
                          child: pending.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 80, color: AppColors.success),
                                    SizedBox(height: 24),
                                    Text('Session Complete', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Text('All students have been processed.', style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('UP NEXT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 2)),
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
                                  Text(activeStudent?.name ?? '', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                                  const SizedBox(height: 8),
                                  Text('Roll No: ${activeStudent?.rollNo} · $subject', style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                                  const SizedBox(height: 48),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            if (activeStudent != null) {
                                              ref.read(skippedStudentsProvider.notifier).skip(activeStudent.id);
                                            }
                                          },
                                          icon: const Icon(Icons.person_off),
                                          label: const Text('Mark Absent', style: TextStyle(fontSize: 16)),
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
                                          label: const Text('Start Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                        const Text('Today\'s Roster', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        Text('${completed.length} done · ${skipped.length} absent', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Row(
                                        children: [
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: completed.length,
                                              child: Container(height: 8, color: AppColors.success),
                                            ),
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: skipped.length,
                                              child: Container(height: 8, color: AppColors.accent),
                                            ),
                                          if (allStudents.isNotEmpty)
                                            Expanded(
                                              flex: pending.length,
                                              child: Container(height: 8, color: Colors.grey.shade200),
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
                                    final isDone = completed.contains(st.id);
                                    final isSkipped = skipped.contains(st.id);
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
                                        title: Text(st.name, style: TextStyle(fontWeight: isNext ? FontWeight.bold : FontWeight.normal, color: textColor)),
                                        subtitle: Text('Roll No: ${st.rollNo}', style: TextStyle(color: textColor.withOpacity(0.7))),
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
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Text(
                'Call the child to the board · tap Start session',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
