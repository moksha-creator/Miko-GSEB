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
    final questions = await mockService.loadSubjectQuiz(level);

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

    final isCorrect = _questions[_currentQuestionIndex].checkAnswer(answer);
    if (isCorrect) _score++;
    
    _answers[_currentQuestionIndex] = answer;
    _correctList[_currentQuestionIndex] = isCorrect;

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
    if (student != null) {
      ref.read(skippedStudentsProvider.notifier).skip(student.id);
    }
    _completeAssessmentFlow(isSkip: true);
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('This will end the assessment and complete the session. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeAssessmentFlow(isSkip: true); // End abruptly
            },
            child: const Text('End Session', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _completeAssessmentFlow({bool isSkip = false}) {
    _timer?.cancel();
    _flutterTts.stop();
    
    final student = ref.read(selectedStudentProvider);
    final subject = ref.read(selectedSubjectProvider);

    if (student != null && !isSkip) {
      final sessionRecord = AssessmentSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: student.id,
        timestamp: DateTime.now(),
        subject: subject,
        totalQuestions: _questions.length,
        score: _score,
        answers: _answers.map((a) => a?.toString() ?? 'skipped').toList(),
        correctList: _correctList,
      );
      ref.read(reportingLogProvider.notifier).addSession(sessionRecord);
      ref.read(completedStudentsProvider.notifier).markCompleted(student.id);
    }

    final allStudents = ref.read(allStudentsProvider);
    final completed = ref.read(completedStudentsProvider);
    final skipped = ref.read(skippedStudentsProvider);
    final pending = allStudents.where((s) => !completed.contains(s.id) && !skipped.contains(s.id)).toList();

    if (pending.isNotEmpty) {
      ref.read(selectedStudentProvider.notifier).select(pending.first);
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
                  TextButton.icon(
                    onPressed: _endSession,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Session'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
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
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
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

                      const SizedBox(height: 32),
                      
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
                            TextButton(
                              onPressed: _skipStudent,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: const Text('Skip Student', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: (currentQ.type == 'mcq' && _selectedAnswer == null) ? null : () => _submitAnswer(_selectedAnswer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Done', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
    if (currentQ.type == 'mcq') {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: currentQ.options?.length ?? 0,
        itemBuilder: (context, index) {
          final option = currentQ.options![index];
          final isSelected = _selectedAnswer == option;
          final isImage = option.startsWith('assets/') || option.startsWith('[image:') || option.contains(RegExp(r'[☀-⛿✀-➿ἰ0-ὟFὠ0-ὤFὨ0-ὯFᾐ0-ᾟF]'));
          
          return InkWell(
            onTap: () {
              setState(() {
                _selectedAnswer = option;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: isImage 
                  ? (option.startsWith('assets/') ? Image.network(option, height: 60, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)) : Text(option, style: const TextStyle(fontSize: 48)))
                  : Text(
                      option,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
              ),
            ),
          );
        },
      );
    } else {
      return InteractivePuzzleWidget(
        question: currentQ,
        onSubmit: (answer) {
          setState(() {
            _selectedAnswer = answer;
          });
          _submitAnswer(answer); // Auto-submit for puzzle
        },
      );
    }
  }
}
