import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  int _timeLeftSeconds = 300; // 5-minute timer
  Timer? _timer;
  bool _isSpeaking = false;
  bool _isRecording = false; // Microphone voice animation control
  final FlutterTts _flutterTts = FlutterTts();
  String? _overrideAIInstruction;

  // Netflix-style next kid loader state variables
  bool _showNextStudentLoader = false;
  int _loaderSecondsLeft = 5;
  Timer? _loaderTimer;

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
      if (mounted) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⏰ Assessment time limit reached for this candidate!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _completeAssessmentFlow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loaderTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _submitAnswer(dynamic answer) {
    final currentQ = _questions[_currentQuestionIndex];
    final isCorrect = answer != null && currentQ.validateAnswer(answer);
    
    setState(() {
      _answers[_currentQuestionIndex] = answer == null ? "skipped" : answer;
      _correctList[_currentQuestionIndex] = isCorrect;
      _score = _correctList.where((e) => e).length;
      _selectedAnswer = null; // reset for next question
    });

    final genericPositiveFeedback = [
      ref.read(localeProvider) == AppLanguage.gujarati ? "અદ્ભુત પ્રયાસ! 🌟 ચાલો જોઈએ આગળ શું છે!" : "Amazing effort! 🌟 Let's see what is next!",
      ref.read(localeProvider) == AppLanguage.gujarati ? "ખૂબ સરસ! તમે શાનદાર કામ કરી રહ્યા છો! 🚀" : "Super! You are doing fantastic! 🚀",
      ref.read(localeProvider) == AppLanguage.gujarati ? "આગળ વધો! ચાલો આગળનું જોઈએ! ✨" : "On we go! Let's explore the next one! ✨",
      ref.read(localeProvider) == AppLanguage.gujarati ? "સમજાઈ ગયું! ચાલો આ યાત્રાને આગળ વધારીએ! 🎉" : "Got it! Let's keep this adventure moving! 🎉",
      ref.read(localeProvider) == AppLanguage.gujarati ? "અદભૂત કાર્ય! શાનદાર ઉર્જા! 🌈" : "Wonderful work! Sparkling energy! 🌈",
    ];
    final randomIndex = DateTime.now().millisecond % genericPositiveFeedback.length;
    
    final feedbackText = isCorrect || answer == "(Teacher Verified)"
        ? genericPositiveFeedback[randomIndex]
        : (answer == null || answer == "skipped" 
            ? "No worries, let's move to the next one!" 
            : "Good try! The correct answer was ${currentQ.correctAnswers.isNotEmpty ? currentQ.correctAnswers.first : 'something else'}.");
    
    setState(() {
      _overrideAIInstruction = feedbackText;
    });

    _flutterTts.speak(_overrideAIInstruction!);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _overrideAIInstruction = null;
        });
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _speakCurrentQuestion();
    } else {
      _timer?.cancel();
      _flutterTts.stop();
      
      // Mark current student as completed!
      final student = ref.read(selectedStudentProvider);
      if (student != null) {
        ref.read(completedStudentsProvider.notifier).markCompleted(student.id);
      }
      
      _completeAssessmentFlow();
    }
  }

  void _completeAssessmentFlow() {
    // Find next eligible student
    final allStus = ref.read(allStudentsProvider);
    final completed = ref.read(completedStudentsProvider);
    final skipped = ref.read(skippedStudentsProvider);

    final nextStudent = allStus.firstWhere(
      (s) => !completed.contains(s.id) && !skipped.contains(s.id),
      orElse: () => Student(
        id: 'none',
        rollNo: 0,
        name: '',
        avatarColor: '#000000',
        avatarAsset: '',
        currentLevels: {},
        flaggedConcepts: [],
        recentSessions: [],
      ),
    );

    if (nextStudent.id != 'none') {
      setState(() {
        _showNextStudentLoader = true;
        _loaderSecondsLeft = 5;
      });
      _startLoaderTimer(nextStudent);
    } else {
      // All done! Show celebration dialogue
      _showCelebrationDialog();
    }
  }

  void _startLoaderTimer(Student nextStudent) {
    _loaderTimer?.cancel();
    _loaderTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_loaderSecondsLeft > 1) {
            _loaderSecondsLeft--;
          } else {
            _loaderTimer?.cancel();
            _proceedToNextStudent(nextStudent);
          }
        });
      }
    });
  }

  void _proceedToNextStudent(Student nextStudent) async {
    ref.read(selectedStudentProvider.notifier).select(nextStudent);
    setState(() {
      _isLoadingQuestions = true;
      _showNextStudentLoader = false;
    });
    
    final questions = await ref.read(mockDataServiceProvider).loadQuestionsForSubject(nextStudent.currentLevels.keys.first);
    
    if (mounted) {
      setState(() {
        _questions = questions;
        _currentQuestionIndex = 0;
        _answers = List.filled(_questions.length, null);
        _correctList = List.filled(_questions.length, false);
        _score = 0;
        _timeLeftSeconds = 300; // Reset 5-minute timer
        _overrideAIInstruction = null;
        _isLoadingQuestions = false;
      });
      _startTimer();
      _initTts();
    }
  }

  void _onAssessNowPressed(Student nextStudent) {
    _loaderTimer?.cancel();
    _proceedToNextStudent(nextStudent);
  }

  void _onCancelLoaderPressed() {
    _loaderTimer?.cancel();
    setState(() {
      _showNextStudentLoader = false;
    });
    context.go('/');
  }



  void _skipStudent() {
    final student = ref.read(selectedStudentProvider);
    if (student != null) {
      ref.read(skippedStudentsProvider.notifier).skip(student.id);
    }
    _timer?.cancel();
    _flutterTts.stop();
    _completeAssessmentFlow();
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _overrideAIInstruction = null;
      });
      _speakCurrentQuestion();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Student? _getNextStudentName() {
    final allStus = ref.read(allStudentsProvider);
    final completed = ref.read(completedStudentsProvider);
    final skipped = ref.read(skippedStudentsProvider);
    final current = ref.read(selectedStudentProvider);

    for (final s in allStus) {
      if (s.id == current?.id) continue;
      if (!completed.contains(s.id) && !skipped.contains(s.id)) {
        return s;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final student = ref.watch(selectedStudentProvider) ?? Student(
      id: 's001',
      rollNo: 1,
      name: 'Aarav Patel',
      avatarColor: '#E85D55',
        avatarAsset: '',
      currentLevels: {'Mathematics': 2, 'Science': 2, 'Language': 1, 'Social Studies': 2},
      flaggedConcepts: [],
      recentSessions: [],
    );

    final currentQuestion = _questions[_currentQuestionIndex];
    final nextStudent = _getNextStudentName();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Warning alert top banner
              if (_timeLeftSeconds <= 60 && nextStudent != null)
                Container(
                  color: Colors.amber.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '⚠️ 1 Minute Left! Next candidate up is Roll #${nextStudent.rollNo} ${nextStudent.name}. Please get ready!',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: _buildAnswerArena(currentQuestion),
                ),
              ),
            ],
          ),
          
          if (_showNextStudentLoader && nextStudent != null)
            Positioned(
              top: 24,
              right: 24,
              child: _buildNetflixLoader(nextStudent),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerArena(QuizQuestion question) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015), 
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation top bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: const Text('Exit Assessment?'),
                      content: const Text('Are you sure you want to quit today\'s assessment session?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/');
                          },
                          child: const Text('Exit'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Assessment: Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.subject,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Question card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isSpeaking)
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat()).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.25, 1.25),
                        duration: 1.2.seconds,
                        curve: Curves.easeInOut,
                      ).fadeIn(duration: 400.ms).fadeOut(delay: 600.ms, duration: 400.ms),
                      
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
                        ],
                      ),
                      child: const Center(
                        child: Text('🤖', style: TextStyle(fontSize: 26)),
                      ),
                    ).animate(target: _isSpeaking ? 1 : 0).shake(duration: 500.ms),
                  ],
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Text(
                    _overrideAIInstruction ?? question.text,
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w900, 
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Speaker button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _speakCurrentQuestion,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // MCQ Cards Choice List
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: question.options.map((opt) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _submitAnswer(opt.value),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.12), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.label, 
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 50.ms).scale(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Interactive Microphone Panel + Action buttons (Skip / Back)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back / Skip left area
              Row(
                children: [
                  if (_currentQuestionIndex > 0) ...[
                    OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      _submitAnswer(null); // submit null to skip question
                    },
                    icon: const Icon(Icons.redo_rounded, size: 16, color: Colors.white),
                    label: const Text('Skip Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),

              // Teacher Verified Button (Only for verbal questions)
              if (question.type == QuestionType.verbal)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _submitAnswer("(Teacher Verified)");
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 28, color: Colors.white),
                      label: const Text('Mark Heard & Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap when child has answered',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),

              // 5-Minute Timer Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeftSeconds <= 30 ? Colors.red.shade50 : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _timeLeftSeconds <= 30 ? Colors.red.shade300 : AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined, 
                      size: 16, 
                      color: _timeLeftSeconds <= 30 ? Colors.red : AppColors.primary
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_timeLeftSeconds),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _timeLeftSeconds <= 30 ? Colors.red : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        backgroundColor: Colors.white,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 SESSION COMPLETE! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.success, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              const Text(
                'Class evaluations completed successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'All present candidates have completed today\'s questions. Metrics have been updated and synced to the school dashboard!',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🏆', style: TextStyle(fontSize: 48)),
                  SizedBox(width: 20),
                  Text('🌟', style: TextStyle(fontSize: 48)),
                  SizedBox(width: 20),
                  Text('🚀', style: TextStyle(fontSize: 48)),
                ],
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                ),
                child: const Text('Back to Home Board 🎒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetflixLoader(Student nextStudent) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Sleek Dark slate
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'UP NEXT',
                style: TextStyle(
                  color: Colors.red, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                'Starting in ${_loaderSecondsLeft}s',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular progress wrapper around Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: _loaderSecondsLeft / 5,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: nextStudent.avatarAsset.isNotEmpty ? AssetImage(nextStudent.avatarAsset) : null,
                    backgroundColor: Color(int.tryParse(nextStudent.avatarColor.replaceFirst('#', '0xFF')) ?? 0xFF3B82F6),
                    child: nextStudent.avatarAsset.isEmpty ? Text(nextStudent.initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)) : null,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextStudent.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll No. ${nextStudent.rollNo}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onCancelLoaderPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onAssessNowPressed(nextStudent),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Assess Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ).animate().slideX(begin: 0.1, end: 0, duration: 250.ms).fadeIn(),
    );
  }

  }

Color _colorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}
