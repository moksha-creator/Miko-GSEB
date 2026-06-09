import re

# 1. student_profiles_screen.dart
with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'r') as f:
    text = f.read()

# Remove the white subject card
subject_card = """                      // White subject card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                subjectIcon,
                                style: const TextStyle(fontSize: 8, color: Colors.white, height: 1.1, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  activeSubject,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),"""

text = text.replace(subject_card, "")

with open('packages/student_ipad/lib/screens/student_profiles_screen.dart', 'w') as f:
    f.write(text)

# 2. quiz_screen.dart
with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'r') as f:
    quiz_text = f.read()

# Remove Skip Candidate button
skip_cand = """              // Prominent Skip Button
              ElevatedButton.icon(
                onPressed: _skipStudent,
                icon: const Icon(Icons.skip_next_rounded, size: 20, color: Colors.white),
                label: const Text('Skip candidate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),"""

quiz_text = quiz_text.replace(skip_cand, "")

with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'w') as f:
    f.write(quiz_text)

