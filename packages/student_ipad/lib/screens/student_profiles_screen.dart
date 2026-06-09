import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_core/shared_core.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;

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
  void toggle() => state = !state;
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
  String _searchQuery = "";
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
              ref.invalidate(classRosterProvider);
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
    final rosterAsync = ref.watch(classRosterProvider);
    final allStudents = ref.watch(allStudentsProvider);
    final completedIds = ref.watch(completedStudentsProvider);
    final skippedIds = ref.watch(skippedStudentsProvider);
    final isGuj = ref.watch(isGujaratiProvider);

    // Calculate active queue and displayed list
    final activeQueue = allStudents.where((s) => !completedIds.contains(s.id) && !skippedIds.contains(s.id)).toList();
    final displayedStudents = activeQueue.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).take(10).toList();

    // Auto-select current assessing student
    Student? nowAssessing = ref.watch(selectedStudentProvider);
    if (nowAssessing == null || !displayedStudents.any((s) => s.id == nowAssessing?.id)) {
      if (displayedStudents.isNotEmpty) {
        nowAssessing = displayedStudents.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedStudentProvider.notifier).select(nowAssessing);
        });
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: rosterAsync.when(
        data: (profile) => Column(
          children: [
            // Top Header section
            _buildBlueHeader(profile),
            
            // Main Panel area split into Left (Now Assessing + Batch of 10) and Right (Skipped Queue)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LEFT COLUMN
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Now Assessing Main Card (Light Blue themed)
                          if (nowAssessing != null)
                            _buildNowAssessingCard(nowAssessing, activeQueue, isGuj)
                          else
                            _buildAllCompletedCard(isGuj),
                          
                          const SizedBox(height: 16),
                          
                          // Students Today Section
                          _buildStudentsTodayLabel(displayedStudents.length),
                          const SizedBox(height: 8),
                          
                          // Active Students grid of 10
                          Expanded(
                            child: _buildStudentsGrid(displayedStudents, nowAssessing, activeQueue, isGuj),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // RIGHT COLUMN: Skipped Section
                    Expanded(
                      flex: 3,
                      child: _buildRightSidePanel(allStudents, skippedIds, isGuj),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom footer instruction bar
            _buildPlayfulFooter(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.accent))),
      ),
    );
  }

  // Header Widget (Exactly matching mockup)
  Widget _buildBlueHeader(ClassProfile profile) {
    final activeSubject = ref.watch(selectedSubjectProvider);
    final icons = {'Mathematics': '➕', 'Science': '🌿', 'Language': '📖', 'Social Studies': '🌍'};
    final subjectIcon = icons[activeSubject] ?? '➕';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Logo + Class 5-B
            Row(
              children: [
                // Mascot Icon
                _buildMikoLogo(size: 52),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class ${profile.grade}-${profile.section}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const Text(
                      'Smart Board Assessment',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            
            // Center: This week's subject (Mathematics)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      subjectIcon,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "This week's subject",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      ),
                      Text(
                        activeSubject,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right: Language Selector
            Consumer(builder: (context, ref, _) {
              final isGuj = ref.watch(isGujaratiProvider);
              return GestureDetector(
                onTap: () => ref.read(isGujaratiProvider.notifier).toggle(),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isGuj ? const Color(0xFF3B82F6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'English',
                          style: TextStyle(color: !isGuj ? Colors.white : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isGuj ? const Color(0xFF3B82F6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'ગુજરાતી',
                          style: TextStyle(color: isGuj ? Colors.white : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Now Assessing Card (Blue themed, 3-column layout: 1: Avatar, 2: Info/Subject, 3: Vertically stacked buttons)
  Widget _buildNowAssessingCard(Student student, List<Student> activeQueue, bool isGuj) {
    final activeSubject = ref.watch(selectedSubjectProvider);
    final icons = {'Mathematics': '➕➖\n✖️➗', 'Science': '🌿', 'Language': '📖', 'Social Studies': '🌍'};
    final subjectIcon = icons[activeSubject] ?? '➕➖\n✖️➗';

    return Container(
      height: 256,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue Background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.blue.shade200.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Top Left Blue Badge
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'NOW ASSESSING',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                // Column 1: Big profile picture (Avatar) with decorative patterns
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft blue glow background container
                        Container(
                          width: 156,
                          height: 156,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 4),
                            color: const Color(0xFFDBEAFE),
                          ),
                        ),
                        // Dotted border simulator
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.2), 
                              width: 2.0,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: AssetImage(_getAvatarAsset(student.id)),
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Vertical divider
                Container(
                  width: 1.5,
                  color: const Color(0xFFDBEAFE),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                
                // Column 2: Name + Roll No + Subject card
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_t('Roll No.', isGuj)} ${student.rollNo}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(height: 16),
                      
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                
                // Vertical divider
                Container(
                  width: 1.5,
                  color: const Color(0xFFDBEAFE),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                
                // Column 3: The 2 CTA buttons (stacked vertically)
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(selectedStudentProvider.notifier).select(student);
                          context.go('/be-ready');
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        label: Text(
                          _t(_t('Start Assessment', isGuj), isGuj),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Green
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fallback card when all students are completed
  Widget _buildAllCompletedCard(bool isGuj) {
    return Container(
      height: 245,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _t(_t('All Active Students Evaluated!', isGuj), isGuj),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
          ],
        ),
      ),
    );
  }

  // Label widget
  Widget _buildStudentsTodayLabel(int count) {
    return Row(
      children: [
        Text(
          'Students Today ($count)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  // Student grid today (exactly matching the small student tiles with Skip button)
  Widget _buildStudentsGrid(List<Student> students, Student? selectedStudent, List<Student> activeQueue, bool isGuj) {
    if (students.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const int cols = 5;
        const double spacing = 16.0;
        final double totalWidth = constraints.maxWidth;
        final double itemWidth = (totalWidth - (cols - 1) * spacing) / cols;
        // Use a 0.8 aspect ratio for taller cards to fit buttons comfortably
        final double childRatio = 0.8;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childRatio,
          ),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final isSelected = selectedStudent?.id == student.id;

            // Compute dynamic sizes based on the tile size
            final double avatarRadius = math.min(36.0, itemWidth * 0.22);
            final double nameSize = math.max(12.0, math.min(15.0, itemWidth * 0.09));
            final double rollSize = math.max(9.0, math.min(12.0, itemWidth * 0.07));
            final double buttonTextSize = math.max(13.0, math.min(15.0, itemWidth * 0.10));

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(selectedStudentProvider.notifier).select(student),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.2 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: AssetImage(_getAvatarAsset(student.id)),
                        backgroundColor: Colors.grey.shade100,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        student.name,
                        style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_t('Roll No.', isGuj)} ${student.rollNo}',
                        style: TextStyle(fontSize: rollSize, color: const Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(skippedStudentsProvider.notifier).skip(student.id);
                          if (isSelected) {
                            final remaining = activeQueue.where((s) => s.id != student.id).toList();
                            if (remaining.isNotEmpty) {
                              ref.read(selectedStudentProvider.notifier).select(remaining.first);
                            } else {
                              ref.read(selectedStudentProvider.notifier).select(null);
                            }
                          }
                        },
                        icon: Icon(Icons.skip_next_rounded, size: buttonTextSize + 4, color: const Color(0xFF2563EB)),
                        label: Text(_t('Skip', isGuj), style: TextStyle(fontSize: buttonTextSize, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: const BorderSide(color: Color(0xFFEFF6FF), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: math.max(8.0, itemWidth * 0.04), horizontal: 16),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }

  // Right Side Panel: Skipped Today + Don't Worry alert card
  Widget _buildRightSidePanel(List<Student> allStudents, Set<String> skippedIds, bool isGuj) {
    final skippedStus = allStudents.where((s) => skippedIds.contains(s.id)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6), // soft slate/blue background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skipped Header
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                _t('Skipped Today', isGuj) + ' (${skippedStus.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          // Skipped Cards list
          Expanded(
            child: skippedStus.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('☀️', style: TextStyle(fontSize: 24)),
                          SizedBox(height: 8),
                          Text(
                            _t('No skipped children!', isGuj),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: skippedStus.length,
                    itemBuilder: (context, index) {
                      final student = skippedStus[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage(_getAvatarAsset(student.id)),
                              backgroundColor: Colors.grey.shade100,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_t('Roll No.', isGuj)} ${student.rollNo}',
                                    style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Re-present action button (Mark Present)
                            InkWell(
                              onTap: () {
                                ref.read(skippedStudentsProvider.notifier).unskip(student.id);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF3B82F6)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Mark Present',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Buffer day Alert Card at the bottom of panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // soft blue background
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Don't worry!",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "We will assess them\non the next buffer day.",
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), height: 1.3),
                      ),
                    ],
                  ),
                ),
                // Calendar cute illustration card
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.shade100.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top blue binder strip
                      Container(
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(width: 3, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(1))),
                            Container(width: 3, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(1))),
                          ],
                        ),
                      ),
                      // Calendar face body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Eyes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle)),
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Smile & Cheeks
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: 3, height: 2, decoration: const BoxDecoration(color: Color(0xFFFCA5A5), shape: BoxShape.circle)), // Blush L
                                  const SizedBox(width: 1),
                                  const Text('◡', style: TextStyle(fontSize: 8, height: 1.0, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 1),
                                  Container(width: 3, height: 2, decoration: const BoxDecoration(color: Color(0xFFFCA5A5), shape: BoxShape.circle)), // Blush R
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Playful footer
  Widget _buildPlayfulFooter() {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left robot mascot with audio waves
            _buildMikoLogo(size: 32),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 1.5, height: 8, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(1))),
                const SizedBox(width: 1.5),
                Container(width: 1.5, height: 12, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(1))),
                const SizedBox(width: 1.5),
                Container(width: 1.5, height: 16, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(1))),
              ],
            ),
            const SizedBox(width: 12),
            
            // Center instruction text
            const Text(
              'Call the child to the board and tap Start Assessment. ⭐',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMikoLogo({double size = 48}) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Headphones left
          Positioned(
            left: 0,
            child: Container(
              width: size * 0.2,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Headphones right
          Positioned(
            right: 0,
            child: Container(
              width: size * 0.2,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Head band
          Positioned(
            top: size * 0.05,
            child: Container(
              width: size * 0.7,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
          // Face container
          Container(
            width: size * 0.8,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // dark face plate
              borderRadius: BorderRadius.circular(size * 0.25),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.8), // cyan border
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Eye Left
                Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8), // glowing cyan eye
                    shape: BoxShape.circle,
                  ),
                ),
                // Eye Right
                Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
