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
    if (student != null) {
      ref.read(skippedStudentsProvider.notifier).skip(student.id);
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
            'This ends the current student\\'s session. '
            'Their answers so far are saved.'),
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

    if (student != null && !isSkip) {
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
    if (currentQ.type == QuestionType.mcq) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = currentQ.options.length <= 2 ? 1 : 2;
          final tileWidth = (constraints.maxWidth - (cols - 1) * 10) / cols;
          // minimum tile height: 80px; scale up for longer text
          final tileHeight = tileWidth * 0.55;   // aspect ~1.8:1

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: tileHeight.clamp(80.0, 160.0),
            ),
            itemCount: currentQ.options.length,
            itemBuilder: (context, index) {
              final opt = currentQ.options[index];
              final isSelected = _selectedAnswer == opt.value;
              return InkWell(
                onTap: () => setState(() => _selectedAnswer = opt.value),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.12),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: opt.value.startsWith('assets/')
                        ? Image.network(
                            opt.value,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40),
                          )
                        : Text(
                            opt.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: cols == 1 ? 16 : 14,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),
              );
            },
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
class InteractivePuzzleWidget extends StatefulWidget {
  final QuizQuestion question;
  final ValueChanged<dynamic> onSubmit;

  const InteractivePuzzleWidget({Key? key, required this.question, required this.onSubmit}) : super(key: key);

  @override
  _InteractivePuzzleWidgetState createState() => _InteractivePuzzleWidgetState();
}

class _InteractivePuzzleWidgetState extends State<InteractivePuzzleWidget> {
  late List<String> _sequenceItems;
  late Map<int, String?> _itemAssignments;
  late List<String> _buckets;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    if (widget.question.matchingPairs.isNotEmpty) {
      _itemAssignments = {};
      _items = [];
      final bucketSet = <String>{};
      for (int i = 0; i < widget.question.matchingPairs.length; i++) {
        final pair = widget.question.matchingPairs[i];
        _itemAssignments[i] = null;
        _items.add(pair.itemA);
        bucketSet.add(pair.itemB);
      }
      _buckets = bucketSet.toList();
    } else {
      _sequenceItems = List.from(widget.question.sortedOrder)..shuffle();
    }
  }

  Widget _buildDraggableItem(int itemIndex, String itemText, {bool inBucket = false}) {
    final isAsset = itemText.startsWith('assets/');
    final isImage = isAsset || itemText.startsWith('[image:') || itemText.contains(RegExp(r'[\u2600-\u26FF\u2700-\u27BF\u1F300-\u1F5FF\u1F600-\u1F64F\u1F680-\u1F6FF\u1F900-\u1F9FF]'));
    
    final contentWidget = isAsset
        ? Image.network(itemText, height: 35, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 35))
        : Text(
            itemText,
            style: TextStyle(
              fontSize: isImage ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: isImage ? AppColors.primary : AppColors.textPrimary,
            ),
          );

    final itemWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: inBucket ? 8 : 12, vertical: inBucket ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(inBucket ? 8 : 12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: contentWidget,
    );

    return Draggable<int>(
      data: itemIndex,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.8, child: itemWidget),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: itemWidget),
      child: itemWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.question.matchingPairs.isNotEmpty) {
      final isComplete = !_itemAssignments.values.any((v) => v == null);
      
      final unsortedIndices = _itemAssignments.entries.where((e) => e.value == null).map((e) => e.key).toList();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _buckets.map((bucketLabel) {
              final assignedIndices = _itemAssignments.entries.where((e) => e.value == bucketLabel).map((e) => e.key).toList();
              final isBucketImage = bucketLabel.startsWith('assets/') || bucketLabel.startsWith('[image:');
              
              return DragTarget<int>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    _itemAssignments[details.data] = bucketLabel;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 120,
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty ? AppColors.primaryLight : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: candidateData.isNotEmpty ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                        width: candidateData.isNotEmpty ? 2 : 1
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isBucketImage && bucketLabel.startsWith('assets/')
                          ? Image.network(bucketLabel, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40))
                          : Text(bucketLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14), textAlign: TextAlign.center),
                        const Divider(),
                        if (assignedIndices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Drop here', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                          )
                        else
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: assignedIndices.map((i) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _itemAssignments[i] = null;
                                });
                              },
                              child: _buildDraggableItem(i, _items[i], inBucket: true),
                            )).toList(),
                          )
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          DragTarget<int>(
            onAcceptWithDetails: (details) {
              setState(() {
                _itemAssignments[details.data] = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? AppColors.primaryLight.withValues(alpha: 0.3) : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: candidateData.isNotEmpty ? AppColors.primary : AppColors.primaryLight,
                    width: candidateData.isNotEmpty ? 2 : 1
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Drag Items to Match', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: unsortedIndices.map((i) => _buildDraggableItem(i, _items[i])).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isComplete ? () {
              widget.onSubmit(_itemAssignments);
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Submit Matches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else {
      // Sequence / Sorting
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: _sequenceItems.length,
              itemBuilder: (context, index) {
                final item = _sequenceItems[index];
                final isImage = item.startsWith('assets/') || item.startsWith('[image:') || item.contains(RegExp(r'[\u2600-\u26FF\u2700-\u27BF\u1F300-\u1F5FF\u1F600-\u1F64F\u1F680-\u1F6FF\u1F900-\u1F9FF]'));
                return Container(
                  key: ValueKey(item),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: item.startsWith('assets/') ? Align(alignment: Alignment.centerLeft, child: Image.network(item, height: 30, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 30))) : Text(
                          item, 
                          style: TextStyle(
                            fontSize: isImage ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: isImage ? AppColors.primary : AppColors.textPrimary,
                          )
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                setState(() {
                                  final temp = _sequenceItems[index];
                                  _sequenceItems[index] = _sequenceItems[index - 1];
                                  _sequenceItems[index - 1] = temp;
                                });
                              },
                            )
                          else
                            const SizedBox(width: 32, height: 32),
                            
                          if (index < _sequenceItems.length - 1)
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                setState(() {
                                  final temp = _sequenceItems[index];
                                  _sequenceItems[index] = _sequenceItems[index + 1];
                                  _sequenceItems[index + 1] = temp;
                                });
                              },
                            )
                          else
                            const SizedBox(width: 32, height: 32),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onSubmit(_sequenceItems);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Submit Sequence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}
