import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/models/reporting_models.dart';
import 'package:shared_core/services/reporting_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_core/shared_core.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'student_profiles_screen.dart';
import 'quiz/question_templates.dart';
import '../providers/planner_state_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<QuizQuestion> _questions = [];
  bool _isLoadingQuestions = true;

  int _currentQuestionIndex = 0;
  dynamic _selectedAnswer;
  int _score = 0;
  int _timeLeftSeconds = 180; // 3-minute timer
  Timer? _timer;
  bool _isPaused = false;
  DateTime _questionStartTime = DateTime.now();
  bool _isSpeaking = false;
  final FlutterTts _flutterTts = FlutterTts();

  late List<dynamic> _answers;
  late List<bool> _correctList;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = ref.read(selectedStudentProvider);
      if (student != null) {
        _proceedToNextStudent(student);
      }
    });
  }

  void _initTts() async {
    await _flutterTts.setLanguage(ref.read(localeProvider) == AppLanguage.gujarati ? "gu-IN" : "en-IN");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
    
    _speakCurrentQuestion();
  }

  void _speakCurrentQuestion() async {
    final currentQ = _questions[_currentQuestionIndex];
    String textToSpeak = currentQ.text;
    
    await _flutterTts.stop();
    
    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }
    
    await _flutterTts.speak(textToSpeak);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          if (_timeLeftSeconds > 0) {
            _timeLeftSeconds--;
          } else {
            _timer?.cancel();
            _autoSubmitDueToTimeout();
          }
        });
      }
    });
  }

  void _autoSubmitDueToTimeout() {
    _submitAnswer(_selectedAnswer);
  }

  Future<void> _proceedToNextStudent(Student student) async {
    if (mounted) {
      setState(() {
        _isLoadingQuestions = true;
      });
    }

    final subject = ref.read(selectedSubjectProvider);
    final isGuj = ref.read(isGujaratiProvider);
    final mockService = ref.read(mockDataServiceProvider);
    
    final level = isGuj ? "gujarati" : "grade_5_math_adaptive";
    final questions = await mockService.loadQuestionsForSubject(subject);

    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
        _currentQuestionIndex = 0;
        _selectedAnswer = null;
        _score = 0;
        _answers = List.filled(questions.length, null);
        _correctList = List.filled(questions.length, false);
        _timeLeftSeconds = 180;
        _isPaused = false;
      });
      _questionStartTime = DateTime.now();
      _startTimer();
      _initTts();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _submitAnswer(dynamic answer) {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;

    final currentQ = _questions[_currentQuestionIndex];
    final isCorrect = answer != null && currentQ.validateAnswer(answer);
    if (isCorrect) _score++;
    
    _answers[_currentQuestionIndex] = answer;
    _correctList[_currentQuestionIndex] = isCorrect;
    
    final student = ref.read(selectedStudentProvider);
    final subject = ref.read(selectedSubjectProvider);
    if (student != null) {
      final timeSpent = DateTime.now().difference(_questionStartTime).inSeconds;
      final response = QuizResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: student.id,
        studentName: student.name,
        subject: subject,
        chapter: 'Unit 1',
        questionId: currentQ.id,
        questionText: currentQ.text,
        questionType: currentQ.type,
        isCorrect: isCorrect,
        submittedAnswer: answer?.toString() ?? 'skipped',
        timeSpentSeconds: timeSpent,
        timestamp: DateTime.now(),
      );
      ref.read(reportingServiceProvider).saveResponse(response);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
      _questionStartTime = DateTime.now();
      _speakCurrentQuestion();
    } else {
      _completeAssessmentFlow();
    }
  }

  void _skipStudent() {
    final student = ref.read(selectedStudentProvider);
    final currentCheckpointId = ref.read(classSetupProvider)?.checkpoint ?? 'monthly';
    final subject = ref.read(selectedSubjectProvider);
    
    if (student != null) {
      ref.read(coverageServiceProvider).defer(student.id, currentCheckpointId, subject, DateTime.now());
    }
    _completeAssessmentFlow(isSkip: true);
  }

  void _confirmExitAssessment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Exit assessment?'),
        content: const Text(
            "This ends the current student's session. "
            "Their answers so far are saved."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _timer?.cancel();
              _flutterTts.stop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _completeAssessmentFlow({bool isSkip = false}) {
    _timer?.cancel();
    _flutterTts.stop();
    
    final student = ref.read(selectedStudentProvider);
    final currentCheckpointId = ref.read(classSetupProvider)?.checkpoint ?? 'monthly';
    final subject = ref.read(selectedSubjectProvider);

    if (student != null && !isSkip) {
      ref.read(coverageServiceProvider).markCovered(student.id, currentCheckpointId, subject, DateTime.now());
    }

    final allStudents = ref.read(allStudentsProvider);
    final coverageService = ref.read(coverageServiceProvider);

    final next = coverageService.assignNext(
      eligible: allStudents,
      subjectId: subject,
      checkpointId: currentCheckpointId,
      now: DateTime.now(),
    );

    if (next != null) {
      ref.read(selectedStudentProvider.notifier).select(next);
      context.go('/next-student-transition', extra: isSkip ? null : student?.name);
    } else {
      ref.read(selectedStudentProvider.notifier).select(null);
      context.go('/session-end');
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions || _questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final student = ref.watch(selectedStudentProvider);
    final currentQ = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex) / _questions.length;
    final isWarning = _timeLeftSeconds <= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Roll No: ${student?.rollNo} · ${ref.watch(selectedSubjectProvider)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isWarning ? AppColors.accent.withOpacity(0.1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: isWarning ? AppColors.accent : AppColors.textPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_timeLeftSeconds),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isWarning ? AppColors.accent : AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPaused = !_isPaused;
                      });
                    },
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _confirmExitAssessment,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Exit assessment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // QUESTION AREA
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Progress
                      Row(
                        children: [
                          Text('Q${_currentQuestionIndex + 1} of ${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Question Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentQ.text,
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: _speakCurrentQuestion,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isSpeaking ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.replay, color: _isSpeaking ? AppColors.primary : AppColors.textSecondary, size: 32),
                                    const SizedBox(height: 4),
                                    Text('Repeat', style: TextStyle(color: _isSpeaking ? AppColors.primary : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (isWarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('1 minute remaining', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ),
                        ),

                      const SizedBox(height: 16),
                      
                      // Answer Arena
                      Expanded(
                        child: _buildAnswerArena(currentQ),
                      ),
                      
                      // Bottom Row Buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Skip question — left
                            ElevatedButton.icon(
                              onPressed: () => _submitAnswer(null),
                              icon: const Icon(Icons.redo_rounded, size: 16, color: Colors.white),
                              label: const Text(
                                'Skip Question',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),

                            // Done — right (only for MCQ / options-based questions)
                            if (currentQ.options.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _selectedAnswer != null
                                    ? () => _submitAnswer(_selectedAnswer)
                                    : null,
                                icon: const Icon(Icons.check_rounded, color: Colors.white),
                                label: const Text(
                                  'Done',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  minimumSize: const Size(160, 52),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerArena(QuizQuestion currentQ) {
    switch (currentQ.visualAid) {
      case 'text_only':
        return ChoiceTemplate(question: currentQ, isImage: false, onAnswer: (ans) => setState(() => _selectedAnswer = ans));
      case 'image_choice':
        return ChoiceTemplate(question: currentQ, isImage: true, onAnswer: (ans) => setState(() => _selectedAnswer = ans));
      case 'two_bucket_sort':
        return SortTemplate(question: currentQ, onAnswer: (ans) {
          setState(() => _selectedAnswer = ans);
          _submitAnswer(ans); // Auto-submit for puzzle
        });
      case 'match_pairs':
        return MatchPairsTemplate(question: currentQ, onAnswer: (ans) {
          setState(() => _selectedAnswer = ans);
          _submitAnswer(ans); // Auto-submit for puzzle
        });
      case 'sequence':
        return SequenceTemplate(question: currentQ, onAnswer: (ans) {
          setState(() => _selectedAnswer = ans);
          // Wait to submit until Done is pressed for sequences? The original SequenceTemplate auto-submits.
          // In original quiz_screen sorting auto-submits, but here sequences can be reordered indefinitely.
          // Wait, InteractivePuzzleWidget automatically called onSubmit for sequences when the sorting is correct or "done"?
          // No, let's rely on the Done button for sequences.
        });
      case 'voice_response':
        return VoiceResponseTemplate(question: currentQ, onAnswer: (ans) => setState(() => _selectedAnswer = ans));
      default:
        // Default to choice
        return ChoiceTemplate(question: currentQ, isImage: false, onAnswer: (ans) => setState(() => _selectedAnswer = ans));
    }
  }
}
