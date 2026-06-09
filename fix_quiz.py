import re

with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'r') as f:
    text = f.read()

# 1. Update Questions
new_questions = """  final List<QuizQuestion> _questions = [
    const QuizQuestion(
      id: 'q1',
      subject: 'Environmental Science',
      text: "Which of these animals is known as the king of the jungle?",
      type: QuestionType.mcq,
      options: [
        QuestionOption(label: 'Lion', value: 'Lion'),
        QuestionOption(label: 'Elephant', value: 'Elephant'),
      ],
      correctAnswers: ['Lion'],
      visualAid: 'lion_icon',
    ),
    const QuizQuestion(
      id: 'q2',
      subject: 'Science',
      text: "What do plants need to grow and make their food?",
      type: QuestionType.mcq,
      options: [
        QuestionOption(label: 'Sunlight', value: 'Sunlight'),
        QuestionOption(label: 'Soda', value: 'Soda'),
      ],
      correctAnswers: ['Sunlight'],
    ),
    const QuizQuestion(
      id: 'q3',
      subject: 'Language',
      text: "Can you speak a sentence about your favorite toy?",
      type: QuestionType.voice,
      options: [],
      correctAnswers: [],
    ),
  ];"""

text = re.sub(r'  final List<QuizQuestion> _questions = \[.*?\];', new_questions, text, flags=re.DOTALL)

# 2. Remove the left panel (_buildMascotPanel) from build()
# original:
#           Expanded(
#             child: Row(
#               children: [
#                 // Left Mascot robot info side
#                 Expanded(
#                   flex: 2,
#                   child: _buildMascotPanel(student, currentQuestion),
#                 ),
#                 
#                 // Right Questionnaire arena side
#                 Expanded(
#                   flex: 3,
#                   child: _buildAnswerArena(currentQuestion),
#                 ),
#               ],
#             ),
#           ),
layout_old = """          Expanded(
            child: Row(
              children: [
                // Left Mascot robot info side
                Expanded(
                  flex: 2,
                  child: _buildMascotPanel(student, currentQuestion),
                ),
                
                // Right Questionnaire arena side
                Expanded(
                  flex: 3,
                  child: _buildAnswerArena(currentQuestion),
                ),
              ],
            ),
          ),"""

layout_new = """          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: _buildAnswerArena(currentQuestion),
            ),
          ),"""
text = text.replace(layout_old, layout_new)

# 3. Remove "Skip Candidate" button
skip_cand_old = """              // Prominent Skip Button
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
text = text.replace(skip_cand_old, "")

# 4. Enforce exactly 2 answer buttons + 1 mic (already handled if we change the options length, but let's make sure the mic button is displayed for MCQ if they requested? No, "each assesment should only have 2 options per question and 1 mic (speach rec) question" means maybe 1 mic button available globally for every question, or one question of type Voice. The new questions have 2 options each, and the 3rd question is type Voice.)

with open('packages/student_ipad/lib/screens/quiz_screen.dart', 'w') as f:
    f.write(text)

