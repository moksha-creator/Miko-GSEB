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
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timeLeftSeconds = 180; // 3-minute timer
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

  final List<QuizQuestion> _questions = [
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
      type: QuestionType.verbal,
      options: [],
      correctAnswers: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_questions.length, null);
    _correctList = List.filled(_questions.length, false);
    _startTimer();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
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
    final isCorrect = currentQ.validateAnswer(answer);
    
    setState(() {
      _answers[_currentQuestionIndex] = answer;
      _correctList[_currentQuestionIndex] = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });

    final genericPositiveFeedback = [
      "Amazing effort! 🌟 Let's see what is next!",
      "Super! You are doing fantastic! 🚀",
      "On we go! Let's explore the next one! ✨",
      "Got it! Let's keep this adventure moving! 🎉",
      "Wonderful work! Sparkling energy! 🌈",
    ];
    final randomIndex = DateTime.now().millisecond % genericPositiveFeedback.length;
    
    setState(() {
      _overrideAIInstruction = genericPositiveFeedback[randomIndex];
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

  void _proceedToNextStudent(Student nextStudent) {
    ref.read(selectedStudentProvider.notifier).select(nextStudent);
    setState(() {
      _currentQuestionIndex = 0;
      _answers = List.filled(_questions.length, null);
      _correctList = List.filled(_questions.length, false);
      _score = 0;
      _timeLeftSeconds = 180; // Reset 3-minute timer
      _showNextStudentLoader = false;
      _overrideAIInstruction = null;
    });
    _startTimer();
    _initTts();
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

  String _getAvatarAsset(String id) {
    final avatars = ['aarav', 'ananya', 'arjun', 'dev', 'diya', 'kavya', 'krish', 'mira', 'priya', 'rohan'];
    final idx = id.hashCode % avatars.length;
    return 'assets/avatars/${avatars[idx.abs()]}.png';
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
    final student = ref.watch(selectedStudentProvider) ?? Student(
      id: 's001',
      rollNo: 1,
      name: 'Aarav Patel',
      avatarColor: '#E85D55',
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

  Widget _buildMascotPanel(Student student, QuizQuestion question) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Student Avatar card
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _colorFromHex(student.avatarColor).withOpacity(0.15),
                child: Text(
                  student.name.substring(0, 1),
                  style: TextStyle(color: _colorFromHex(student.avatarColor), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${student.name.split(' ')[0]}'s Assessment", 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 5-Minute Timer Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeftSeconds <= 60 ? Colors.red.shade50 : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _timeLeftSeconds <= 60 ? Colors.red.shade300 : Colors.transparent),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined, 
                      size: 14, 
                      color: _timeLeftSeconds <= 60 ? Colors.red : AppColors.primary
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeLeftSeconds),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _timeLeftSeconds <= 60 ? Colors.red : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Mascot robot
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isSpeaking)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.25, 1.25),
                    duration: 1.2.seconds,
                    curve: Curves.easeInOut,
                  ).fadeIn(duration: 400.ms).fadeOut(delay: 600.ms, duration: 400.ms),

                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(
                    _isSpeaking ? Icons.speaker_phone_rounded : Icons.adb_rounded, 
                    size: 56,
                    color: Colors.white,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).slideY(
                  begin: 0,
                  end: -0.06,
                  duration: 1.8.seconds,
                  curve: Curves.easeInOut,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Speech Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Text(
              _overrideAIInstruction ?? _getAIInstruction(student.name.split(' ')[0]),
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: _overrideAIInstruction != null ? AppColors.primary : AppColors.textPrimary, 
                height: 1.4
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const Spacer(),
          
          // Visual chocolate helper
          if (question.visualAid == 'chocolate_4_2')
            _buildVisualAidContainer(question.visualAid!)
          else
            const SizedBox(height: 60),
            
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildVisualAidContainer(String visualType) {
    return Column(
      children: [
        const Text('🍰 Fraction Visual Aid:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Container(
          height: 60,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade700, width: 2.5),
          ),
          child: Row(
            children: List.generate(4, (index) {
              final isHighlighted = index < 2; 
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isHighlighted ? Colors.orange.shade400 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
        ).animate().fadeIn().scale(),
      ],
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

              // Animated Pulsing Microphone in center
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRecording = !_isRecording;
                      });
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.red : AppColors.primary).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isRecording)
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red.withOpacity(0.4), width: 3),
                              ),
                            ).animate(onPlay: (controller) => controller.repeat()).scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.3, 1.3),
                              duration: 1.seconds,
                            ).fadeOut(duration: 1.seconds),
                          Icon(
                            _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isRecording ? 'Listening... Tap to stop' : 'Tap to Answer Orally',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red.shade700 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // 3-Minute Timer Display
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
                    backgroundImage: AssetImage(_getAvatarAsset(nextStudent.id)),
                    backgroundColor: Colors.white,
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

  String _getAIInstruction(String firstName) {
    switch (_currentQuestionIndex) {
      case 0: return "Hi $firstName! Let's solve today's fraction quest! Tell me what fraction of the chocolate is brown.";
      case 1: return "Excellent. Choose the option that is equivalent to one-half!";
      case 2: return "Amazing progress! Look at the pizza problem and pick the correct fraction.";
      default: return "Answer the question, $firstName!";
    }
  }
}

Color _colorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}
