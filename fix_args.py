import re
with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'r') as f:
    text = f.read()

text = text.replace("_buildNowAssessingCard(nowAssessing, activeQueue)", "_buildNowAssessingCard(nowAssessing, activeQueue, isGuj)")
text = text.replace("_buildStudentsGrid(displayedStudents, nowAssessing, activeQueue)", "_buildStudentsGrid(displayedStudents, nowAssessing, activeQueue, isGuj)")
text = text.replace("children: const [\n                          Text('☀️'", "children: [\n                          const Text('☀️'")

with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'w') as f:
    f.write(text)
