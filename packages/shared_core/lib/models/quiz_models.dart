enum QuestionType {
  mcq,
  multiSelect,
  fillInBlank,
  trueFalse,
  matching,
  sorting,
  reflection,
  verbal
}

class QuestionOption {
  final String label;
  final String value;
  final String? imageUrl;

  const QuestionOption({required this.label, required this.value, this.imageUrl});
}

class MatchingPair {
  final String itemA;
  final String itemB;
  final String? itemABrief;
  final String? itemBBrief;

  const MatchingPair({
    required this.itemA, 
    required this.itemB,
    this.itemABrief,
    this.itemBBrief,
  });
}

class QuizQuestion {
  final String id;
  final String subject;
  final String text;
  final QuestionType type;
  final List<QuestionOption> options;
  final List<String> correctAnswers; // For MCQ, multi-select, true/false, fill-in-the-blank
  final List<MatchingPair> matchingPairs; // For matching
  final List<String> sortedOrder; // For sorting
  final String? visualAid; // Dynamic visuals (e.g. chocolate_4_2)
  final String? voiceAudioFile; // Simulated audio asset path
  final String? instruction;
  final String? expectedAnswer;
  final List<String> acceptableAnswers;
  final String? explanation;
  final String? questionImage;
  final String? questionImageBrief;

  const QuizQuestion({
    required this.id,
    required this.subject,
    required this.text,
    required this.type,
    this.options = const [],
    this.correctAnswers = const [],
    this.matchingPairs = const [],
    this.sortedOrder = const [],
    this.visualAid,
    this.voiceAudioFile,
    this.instruction,
    this.expectedAnswer,
    this.acceptableAnswers = const [],
    this.explanation,
    this.questionImage,
    this.questionImageBrief,
  });

  bool validateAnswer(dynamic answer) {
    if (type == QuestionType.reflection) {
      return true; // Self-reflection is always validated as correct!
    }
    if (type == QuestionType.mcq || type == QuestionType.trueFalse) {
      if (answer is! String) return false;
      return correctAnswers.isNotEmpty && correctAnswers.first.trim().toLowerCase() == answer.trim().toLowerCase();
    }
    if (type == QuestionType.multiSelect) {
      if (answer is! List) return false;
      if (answer.length != correctAnswers.length) return false;
      final correctSet = correctAnswers.map((e) => e.trim().toLowerCase()).toSet();
      final answerSet = answer.map((e) => e.toString().trim().toLowerCase()).toSet();
      return correctSet.difference(answerSet).isEmpty;
    }
    if (type == QuestionType.fillInBlank) {
      if (answer is! String) return false;
      return correctAnswers.isNotEmpty && correctAnswers.first.trim().toLowerCase() == answer.trim().toLowerCase();
    }
    if (type == QuestionType.matching) {
      if (answer is! Map) return false;
      if (answer.length != matchingPairs.length) return false;
      for (int i = 0; i < matchingPairs.length; i++) {
        final pair = matchingPairs[i];
        final val = answer[i] ?? answer[pair.itemA];
        if (val?.toString().trim().toLowerCase() != pair.itemB.trim().toLowerCase()) {
          return false;
        }
      }
      return true;
    }
    if (type == QuestionType.sorting) {
      if (matchingPairs.isNotEmpty) {
        if (answer is! Map) return false;
        if (answer.length != matchingPairs.length) return false;
        for (int i = 0; i < matchingPairs.length; i++) {
          final pair = matchingPairs[i];
          final val = answer[i] ?? answer[pair.itemA];
          if (val?.toString().trim().toLowerCase() != pair.itemB.trim().toLowerCase()) {
            return false;
          }
        }
        return true;
      } else {
        if (answer is! List) return false;
        if (answer.length != sortedOrder.length) return false;
        for (int i = 0; i < sortedOrder.length; i++) {
          if (sortedOrder[i].trim().toLowerCase() != answer[i].toString().trim().toLowerCase()) {
            return false;
          }
        }
        return true;
      }
    }
    if (type == QuestionType.verbal) {
      if (answer is! String) return false;
      if (answer == "(Teacher Verified)") return true;
      if (acceptableAnswers.isNotEmpty) {
        return acceptableAnswers.map((e) => e.trim().toLowerCase()).contains(answer.trim().toLowerCase());
      }
      return correctAnswers.isNotEmpty && correctAnswers.first.trim().toLowerCase() == answer.trim().toLowerCase();
    }
    return false;
  }
}
