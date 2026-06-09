import re

with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'r') as f:
    text = f.read()

# 1. StateProvider issue -> Change to Notifier
prov_old = """// Language Provider
final isGujaratiProvider = StateProvider<bool>((ref) => false);"""
prov_new = """// Language Provider
class IsGujaratiNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}
final isGujaratiProvider = NotifierProvider<IsGujaratiNotifier, bool>(IsGujaratiNotifier.new);"""
text = text.replace(prov_old, prov_new)

# Update the toggle action
text = text.replace("ref.read(isGujaratiProvider.notifier).state = !isGuj", "ref.read(isGujaratiProvider.notifier).toggle()")

# 2. _buildNowAssessingCard arguments
text = text.replace("_buildNowAssessingCard(selectedStudent, activeQueue)", "_buildNowAssessingCard(selectedStudent, activeQueue, isGuj)")

# 3. _buildStudentsGrid arguments
text = text.replace("_buildStudentsGrid(displayedStudents, selectedStudent, activeQueue)", "_buildStudentsGrid(displayedStudents, selectedStudent, activeQueue, isGuj)")

# 4. Remove `const` from `const [\n                            Text('🙈'`
text = text.replace("const [\n                            Text('🙈'", "[\n                            const Text('🙈'")

with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'w') as f:
    f.write(text)

