import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../providers/planner_state_provider.dart';

enum AssessmentState { home, loading, preTransition, activity, postTransition, end }

class AssessmentSessionScreen extends ConsumerStatefulWidget {
  const AssessmentSessionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AssessmentSessionScreen> createState() => _AssessmentSessionScreenState();
}

class _AssessmentSessionScreenState extends ConsumerState<AssessmentSessionScreen> {
  AssessmentState _currentState = AssessmentState.home;
  RosterEntry? _currentStudent;
  
  Timer? _countdownTimer;
  int _timeRemaining = 0;
  bool _isPaused = false;
  
  // Home Settings
  String _selectedLanguage = 'English';
  String? _selectedSubject;
  int _selectedLesson = 1;
  
  // Assessment Data
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _correctAnswersCount = 0;
  
  // Custom Interaction States
  List<String> _sequenceItems = [];
  bool _isRecording = false;
  Map<String, String> _bucketMatches = {};
  Map<String, String> _pairedItems = {};
  String? _selectedMatchLeft;
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _currentState = AssessmentState.loading;
    });
    
    final service = ref.read(mockDataServiceProvider);
    final subjectToLoad = _selectedSubject ?? _currentStudent?.subject ?? 'Math';
    _questions = await service.loadQuestionsForSubject(subjectToLoad, lesson: _selectedLesson);
    _currentQuestionIndex = 0;
    _correctAnswersCount = 0;
    _resetInteractionStates();
    
    if (mounted) {
      setState(() {
        _currentState = AssessmentState.preTransition;
        _timeRemaining = 5;
      });
      _startTimer(() {
        _startActivity();
      });
    }
  }

  void _resetInteractionStates() {
    _selectedOptionIndex = null;
    _isRecording = false;
    _bucketMatches.clear();
    _pairedItems.clear();
    _selectedMatchLeft = null;
    
    if (_questions.isNotEmpty && _currentQuestionIndex < _questions.length) {
      final q = _questions[_currentQuestionIndex];
      if (q.visualAid == 'sequence') {
        _sequenceItems = List.from(q.sortedOrder)..shuffle();
      }
    }
  }

  void _startActivity() {
    setState(() {
      _currentState = AssessmentState.activity;
      _timeRemaining = 180; // 3 minutes
      _isPaused = false;
    });
    _startTimer(() {
      _endActivity();
    });
  }

  void _endActivity() {
    _countdownTimer?.cancel();
    
    if (_currentStudent != null) {
      final timeSpent = 180 - _timeRemaining;
      final lastQ = _questions.isNotEmpty ? _questions[_currentQuestionIndex.clamp(0, _questions.length - 1)].id : '';
      final isPassing = _questions.isNotEmpty && (_correctAnswersCount / _questions.length) >= 0.5;
      
      ref.read(plannerStateProvider.notifier).markStatus(
        _currentStudent!, 
        RosterStatus.completed,
        timeSpentSeconds: timeSpent,
        lastQuestion: lastQ,
        level: isPassing ? 'L2' : 'L1',
      );
    }
    
    setState(() {
      _currentState = AssessmentState.postTransition;
      _timeRemaining = 5;
    });
    _startTimer(() {
      _loadNextOrEnd();
    });
  }
  
  void _forceEndSession() {
    _endActivity();
  }

  void _skipQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _resetInteractionStates();
      });
    } else {
      // Completed all questions early, transition smoothly!
      _endActivity();
    }
  }
  
  void _doneQuestion() {
    final question = _questions[_currentQuestionIndex];
    bool isCorrect = false;

    if (question.type == QuestionType.mcq) {
      if (_selectedOptionIndex == null) return;
      final selectedVal = question.options[_selectedOptionIndex!].value;
      isCorrect = question.validateAnswer(selectedVal);
    } else if (question.type == QuestionType.sorting && question.visualAid == 'sequence') {
      isCorrect = true;
      for (int i = 0; i < question.sortedOrder.length; i++) {
        if (_sequenceItems[i] != question.sortedOrder[i]) isCorrect = false;
      }
    } else if (question.type == QuestionType.sorting && question.visualAid == 'two_bucket_sort') {
      isCorrect = true;
      if (_bucketMatches.length != question.matchingPairs.length) isCorrect = false;
      for (final pair in question.matchingPairs) {
        if (_bucketMatches[pair.itemA] != pair.itemB) isCorrect = false;
      }
    } else if (question.type == QuestionType.matching) {
      isCorrect = true;
      if (_pairedItems.length != question.matchingPairs.length) isCorrect = false;
      for (final pair in question.matchingPairs) {
        if (_pairedItems[pair.itemA] != pair.itemB) isCorrect = false;
      }
    } else {
      isCorrect = true;
    }
    
    if (isCorrect) {
      _correctAnswersCount++;
    }
    
    _skipQuestion();
  }

  void _markAbsent() {
    if (_currentStudent != null) {
      ref.read(plannerStateProvider.notifier).markStatus(_currentStudent!, RosterStatus.absent);
    }
    _loadNextOrEnd();
  }

  void _loadNextOrEnd() {
    final plannerState = ref.read(plannerStateProvider);
    final next = plannerState?.nextStudent;
    setState(() {
      if (next != null) {
        _currentStudent = next;
        _selectedSubject = next.subject; // Reset to student's default
        _currentState = AssessmentState.home;
      } else {
        _currentState = AssessmentState.end;
      }
    });
  }

  void _startTimer(VoidCallback onComplete) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerStateProvider);
    
    if (_currentStudent == null && _currentState != AssessmentState.end) {
      final next = plannerState?.nextStudent;
      if (next != null) {
        _currentStudent = next;
        _selectedSubject = next.subject;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentState != AssessmentState.end) {
            setState(() => _currentState = AssessmentState.end);
          }
        });
        return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      }
    }
    
    switch (_currentState) {
      case AssessmentState.home: return _buildHome(plannerState!);
      case AssessmentState.loading: return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
      case AssessmentState.preTransition: return _buildTransition(isPre: true);
      case AssessmentState.activity: return _buildActivity();
      case AssessmentState.postTransition: return _buildTransition(isPre: false);
      case AssessmentState.end: return _buildEnd(plannerState!);
    }
  }

  Widget _buildHome(PlannerState state) {
    final activeSubjects = state.weeklyPlan.map((w) => w.subject).toSet().toList();
    if (activeSubjects.isEmpty) activeSubjects.add('Math');
    
    if (_selectedSubject == null || !activeSubjects.contains(_selectedSubject)) {
      _selectedSubject = activeSubjects.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classroom Orchestration', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: AppColors.primary),
              items: ['English', 'Spanish', 'Hindi'].map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) => setState(() => _selectedLanguage = val!),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UP NEXT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Text(_currentStudent!.studentName, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.1)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: Text(_currentStudent!.subject, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRealDropdown(
                          'Subject',
                          _selectedSubject!,
                          activeSubjects,
                          (v) => setState(() => _selectedSubject = v),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildRealDropdown(
                          'Lesson Scope',
                          _selectedLesson.toString(),
                          ['1', '2', '3', '4', '5', '6'],
                          (v) => setState(() => _selectedLesson = int.parse(v!)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _startSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Start Session', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: TextButton(
                          onPressed: _markAbsent,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 2)),
                          ),
                          child: const Text('Mark Absent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.centerLeft,
                    child: const Text('Today\'s Roster', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: state.todayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = state.todayEntries[index];
                        final isNext = entry.studentId == _currentStudent!.studentId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isNext ? AppColors.primaryLight : AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isNext ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isNext ? AppColors.primary : AppColors.textMuted,
                                child: Text(entry.studentName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.studentName, style: TextStyle(fontWeight: FontWeight.bold, color: isNext ? AppColors.primary : AppColors.textPrimary)),
                                    Text(entry.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (entry.status == RosterStatus.completed) const Icon(Icons.check_circle, color: AppColors.success),
                              if (entry.status == RosterStatus.absent) const Icon(Icons.cancel, color: AppColors.accent),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(label == 'Lesson Scope' ? 'Lesson $i' : i, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransition({required bool isPre}) {
    return Scaffold(
      backgroundColor: isPre ? AppColors.primary : AppColors.success,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isPre) ...[
              const Icon(Icons.star_rounded, color: Colors.white, size: 80),
              const SizedBox(height: 24),
              const Text('Great job!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(_currentStudent!.studentName, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
            ] else ...[
              const Text('Walk up to the board,', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text(_currentStudent!.studentName, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ],
            const SizedBox(height: 64),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
              child: Center(
                child: Text('$_timeRemaining', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isPre ? FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: _startActivity,
        label: const Text('Skip Wait', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.fast_forward, color: AppColors.primary),
      ) : null,
    );
  }

  Widget _buildActivity() {
    final bool isWarning = _timeRemaining <= 60;
    
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text("No questions available.")));
    }
    
    final question = _questions[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(_currentStudent!.studentName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Text(_currentStudent!.studentName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isWarning ? AppColors.accent.withOpacity(0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isWarning ? AppColors.accent : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: isWarning ? AppColors.accent : AppColors.textSecondary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isWarning ? AppColors.accent : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                    ),
                    child: SingleChildScrollView(
                      child: _buildTemplateRenderer(question),
                    ),
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _skipQuestion,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Skip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _doneQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          Positioned(
            left: 16,
            bottom: 16,
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaused ? AppColors.warning : AppColors.surface,
                    foregroundColor: _isPaused ? Colors.white : AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => setState(() => _isPaused = !_isPaused),
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 16),
                  label: Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: _forceEndSession,
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: const Text('End Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTemplateRenderer(QuizQuestion question) {
    switch (question.visualAid) {
      case 'text_only':
        return _buildChoiceTemplate(question, isImage: false);
      case 'image_choice':
        return _buildChoiceTemplate(question, isImage: true);
      case 'two_bucket_sort':
        return _buildSortTemplate(question);
      case 'match_pairs':
        return _buildMatchPairsTemplate(question);
      case 'sequence':
        return _buildSequenceTemplate(question);
      case 'voice_response':
        return _buildVoiceResponseTemplate(question);
      default:
        return _buildChoiceTemplate(question, isImage: false);
    }
  }

  Widget _buildChoiceTemplate(QuizQuestion question, {required bool isImage}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(question.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3))),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(question.options.length, (i) => _buildChoiceOption(question.options[i], i, isImage)),
        ),
      ],
    );
  }

  Widget _buildChoiceOption(QuestionOption option, int index, bool isImage) {
    final isSelected = _selectedOptionIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedOptionIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isImage ? 100 : 100,
        height: isImage ? 100 : 80,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1), width: isSelected ? 4 : 2),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImage) ...[
              Text(option.value, style: const TextStyle(fontSize: 36)),
            ],
            if (!isImage) ...[
              Text(option.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(option.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppColors.primary)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSortTemplate(QuizQuestion question) {
    final buckets = question.matchingPairs.map((e) => e.itemB).toSet().toList();
    final items = question.matchingPairs.map((e) => e.itemA).toList();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(question.text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3))),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buckets.map((b) => _buildDragTargetBucket(b)).toList(),
        ),
        const SizedBox(height: 48),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: items.where((i) => !_bucketMatches.containsKey(i)).map((i) => Draggable<String>(
            data: i,
            feedback: Material(color: Colors.transparent, child: _buildDraggableItem(i, true)),
            childWhenDragging: Opacity(opacity: 0.3, child: _buildDraggableItem(i, false)),
            child: _buildDraggableItem(i, false),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDragTargetBucket(String label) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        setState(() {
          _bucketMatches[details.data] = label;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final matchedItems = _bucketMatches.entries.where((e) => e.value == label).map((e) => e.key).toList();
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isHovered ? AppColors.primary : AppColors.primary.withOpacity(0.3), width: isHovered ? 4 : 2),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchedItems.map((i) => GestureDetector(
                    onTap: () => setState(() => _bucketMatches.remove(i)),
                    child: _buildDraggableItem(i, false, small: true),
                  )).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDraggableItem(String label, bool isDragging, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 16, vertical: small ? 4 : 8),
      decoration: BoxDecoration(
        color: isDragging ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        boxShadow: isDragging ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10)] : [],
      ),
      child: Text(label, style: TextStyle(fontSize: small ? 10 : 16, fontWeight: FontWeight.bold, color: isDragging ? Colors.white : AppColors.textPrimary)),
    );
  }

  Widget _buildMatchPairsTemplate(QuizQuestion question) {
    final leftItems = question.matchingPairs.map((e) => e.itemA).toList();
    final rightItems = question.matchingPairs.map((e) => e.itemB).toList();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(question.text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3))),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: leftItems.map((p) => _buildMatchLeftItem(p)).toList(),
            ),
            Column(
              children: rightItems.map((p) => _buildMatchRightItem(p)).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchLeftItem(String text) {
    final isSelected = _selectedMatchLeft == text;
    final isPaired = _pairedItems.containsKey(text);
    
    return GestureDetector(
      onTap: () {
        if (!isPaired) setState(() => _selectedMatchLeft = text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPaired ? AppColors.success.withOpacity(0.2) : isSelected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPaired ? AppColors.success : isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2), width: isSelected ? 4 : 2),
        ),
        child: Center(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPaired ? AppColors.success : AppColors.textPrimary))),
      ),
    );
  }
  
  Widget _buildMatchRightItem(String text) {
    final pairedLeft = _pairedItems.entries.where((e) => e.value == text).map((e) => e.key).firstOrNull;
    final isPaired = pairedLeft != null;
    
    return GestureDetector(
      onTap: () {
        if (_selectedMatchLeft != null && !isPaired) {
          setState(() {
            _pairedItems[_selectedMatchLeft!] = text;
            _selectedMatchLeft = null;
          });
        } else if (isPaired) {
          // Tap to unpair
          setState(() => _pairedItems.remove(pairedLeft));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPaired ? AppColors.success.withOpacity(0.2) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPaired ? AppColors.success : AppColors.primary.withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: Column(
            children: [
              Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPaired ? AppColors.success : AppColors.textPrimary)),
              if (isPaired) Text('Matched with $pairedLeft', style: const TextStyle(fontSize: 8, color: AppColors.success), textAlign: TextAlign.center),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildSequenceTemplate(QuizQuestion question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(question.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3))),
          ],
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent SingleChildScrollView
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _sequenceItems.removeAt(oldIndex);
              _sequenceItems.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < _sequenceItems.length; i++)
              Container(
                key: ValueKey(_sequenceItems[i]),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_sequenceItems[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                    ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle, size: 20, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceResponseTemplate(QuizQuestion question) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(question.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3))),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(() => _isRecording = !_isRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRecording ? 160 : 120,
            height: _isRecording ? 160 : 120,
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.accent : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: _isRecording ? AppColors.accent : AppColors.primary, width: 4),
              boxShadow: _isRecording ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)] : [],
            ),
            child: Icon(Icons.mic, size: _isRecording ? 80 : 60, color: _isRecording ? Colors.white : AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
        Text(_isRecording ? 'Listening...' : 'Tap to speak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _isRecording ? AppColors.accent : AppColors.textSecondary)),
        if (question.correctAnswers.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('"${question.correctAnswers.first}"', style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
        ]
      ],
    );
  }

  Widget _buildEnd(PlannerState state) {
    int total = state.todayEntries.length;
    int completed = state.todayEntries.where((e) => e.status == RosterStatus.completed).length;
    int absent = state.todayEntries.where((e) => e.status == RosterStatus.absent).length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 80),
            ),
            const SizedBox(height: 32),
            const Text('Session Complete', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            const Text('All students on today\'s roster have been assessed.', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEndStat('$completed / $total', 'Students Assessed', AppColors.primary),
                const SizedBox(width: 64),
                _buildEndStat('$absent', 'Marked Absent', AppColors.accent),
              ],
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Return to Home', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndStat(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ],
    );
  }
}
