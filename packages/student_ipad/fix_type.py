import re
with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'r') as f:
    text = f.read()
text = text.replace("QuestionType.voice", "QuestionType.verbal")
with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'w') as f:
    f.write(text)
