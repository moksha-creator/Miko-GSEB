import re
with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'r') as f:
    text = f.read()

# 1. Add Providers and translations
new_providers = """
final skippedStudentsProvider = NotifierProvider<SkippedStudentsNotifier, Set<String>>(SkippedStudentsNotifier.new);

// Language Provider
final isGujaratiProvider = StateProvider<bool>((ref) => false);

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
"""
text = text.replace("final skippedStudentsProvider = NotifierProvider<SkippedStudentsNotifier, Set<String>>(SkippedStudentsNotifier.new);", new_providers, 1)

# 2. In build() of _StudentProfilesScreenState, read isGuj
text = text.replace("    final skippedIds = ref.watch(skippedStudentsProvider);", "    final skippedIds = ref.watch(skippedStudentsProvider);\n    final isGuj = ref.watch(isGujaratiProvider);", 1)

text = text.replace("'Good Morning, Teacher!'", "_t('Good Morning, Teacher!', isGuj)")
text = text.replace("'Here\\'s your assessment dashboard for today.'", "_t('Here\\'s your assessment dashboard for today.', isGuj)")
text = text.replace("'Now Assessing'", "_t('Now Assessing', isGuj)")

# Fix the string concatenation for Today's session
text = text.replace("'Today\\'s Session (${activeQueue.length})'", "_t('Today\\'s Session', isGuj) + ' (${activeQueue.length})'")

# Fix buildNowAssessingCard call
text = text.replace("_buildNowAssessingCard(selectedStudent, activeQueue)", "_buildNowAssessingCard(selectedStudent, activeQueue, isGuj)")

# Language selector update
lang_selector_old = """            // Right: Language Selector
            Container(
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
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'English',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Text(
                      'ગુજરાતી',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),"""
lang_selector_new = """            // Right: Language Selector
            Consumer(builder: (context, ref, _) {
              final isGuj = ref.watch(isGujaratiProvider);
              return GestureDetector(
                onTap: () => ref.read(isGujaratiProvider.notifier).state = !isGuj,
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
            }),"""
text = text.replace(lang_selector_old, lang_selector_new)

# _buildNowAssessingCard changes
text = text.replace("Widget _buildNowAssessingCard(Student student, List<Student> activeQueue) {", "Widget _buildNowAssessingCard(Student student, List<Student> activeQueue, bool isGuj) {")

# Remove Subject Math string
sub_text = """                        const Spacer(),
                        Text(
                          '$subjectIcon $activeSubject',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
                        ),"""
text = text.replace(sub_text, "")

# Update Start Assessment text
text = text.replace("'Start Assessment'", "_t('Start Assessment', isGuj)")
# Remove const from label in Start Assessment
text = text.replace("label: const Text(\n                          _t('Start Assessment', isGuj),", "label: Text(\n                          _t('Start Assessment', isGuj),")

# Remove Skip button
skip_btn = """                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(skippedStudentsProvider.notifier).skip(student.id);
                          
                          // Auto select next candidate
                          final remaining = activeQueue.where((s) => s.id != student.id).toList();
                          if (remaining.isNotEmpty) {
                            ref.read(selectedStudentProvider.notifier).select(remaining.first);
                          } else {
                            ref.read(selectedStudentProvider.notifier).select(null);
                          }
                        },
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFF2563EB), size: 20),
                        label: const Text(
                          'Skip Child',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),"""
text = text.replace(skip_btn, "")

# Change all completed card
text = text.replace("Widget _buildAllCompletedCard() {", "Widget _buildAllCompletedCard(bool isGuj) {")
text = text.replace("_buildAllCompletedCard()", "_buildAllCompletedCard(isGuj)")
text = text.replace("'All Active Students Evaluated!'", "_t('All Active Students Evaluated!', isGuj)")
text = text.replace("const [\n            Text('🎉'", "[\n            const Text('🎉'")

text = text.replace("Widget _buildStudentsGrid(List<Student> students, Student? selectedStudent, List<Student> activeQueue) {", "Widget _buildStudentsGrid(List<Student> students, Student? selectedStudent, List<Student> activeQueue, bool isGuj) {")
text = text.replace("_buildStudentsGrid(displayedStudents, selectedStudent, activeQueue)", "_buildStudentsGrid(displayedStudents, selectedStudent, activeQueue, isGuj)")

text = text.replace("final double childRatio = 1.0;", "final double childRatio = 0.82;")
text = text.replace("final double buttonTextSize = math.max(9.0, math.min(11.0, itemWidth * 0.07));", "final double buttonTextSize = math.max(12.0, math.min(14.0, itemWidth * 0.08));")
text = text.replace("backgroundImage: AssetImage('assets/avatars/${student.name.toLowerCase().split(' ')[0]}.png'),", "backgroundImage: AssetImage(_getAvatarAsset(student.id)),")

text = text.replace("'Roll No. ${student.rollNo}'", "'${_t('Roll No.', isGuj)} ${student.rollNo}'")

grid_skip_btn_old = """                        icon: Icon(Icons.skip_next_rounded, size: buttonTextSize + 2, color: const Color(0xFF2563EB)),
                        label: Text('Skip', style: TextStyle(fontSize: buttonTextSize, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: const BorderSide(color: Color(0xFFEFF6FF), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: math.max(2.0, itemWidth * 0.02), horizontal: 12),
                          minimumSize: Size.zero,"""

grid_skip_btn_new = """                        icon: Icon(Icons.skip_next_rounded, size: buttonTextSize + 4, color: const Color(0xFF2563EB)),
                        label: Text(_t('Skip', isGuj), style: TextStyle(fontSize: buttonTextSize, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB))),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          side: const BorderSide(color: Color(0xFFEFF6FF), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: math.max(6.0, itemWidth * 0.04), horizontal: 12),
                          minimumSize: const Size(0, 36),"""

text = text.replace(grid_skip_btn_old, grid_skip_btn_new)

text = text.replace("Widget _buildRightSidePanel(List<Student> allStudents, Set<String> skippedIds) {", "Widget _buildRightSidePanel(List<Student> allStudents, Set<String> skippedIds, bool isGuj) {")
text = text.replace("_buildRightSidePanel(allStudents, skippedIds)", "_buildRightSidePanel(allStudents, skippedIds, isGuj)")

text = text.replace("'Skipped Today (${skippedStus.length})'", "_t('Skipped Today', isGuj) + ' (${skippedStus.length})'")
text = text.replace("'No skipped children!'", "_t('No skipped children!', isGuj)")
text = text.replace("const [\n                            Text('🙈'", "[\n                            const Text('🙈'")

text = text.replace("'Don\\'t worry!'", "_t('Don\\'t worry!', isGuj)")
text = text.replace("'They can try again tomorrow'", "_t('They can try again tomorrow', isGuj)")
text = text.replace("const Text(\n                    _t('Don\\'t worry!', isGuj),", "Text(\n                    _t('Don\\'t worry!', isGuj),")
text = text.replace("const Text(\n                    _t('They can try again tomorrow', isGuj),", "Text(\n                    _t('They can try again tomorrow', isGuj),")

with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'w') as f:
    f.write(text)

