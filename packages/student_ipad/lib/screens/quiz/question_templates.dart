import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

// ----------------------------------------------------------------------
// Choice Template (MCQ)
// ----------------------------------------------------------------------
class ChoiceTemplate extends StatefulWidget {
  final QuizQuestion question;
  final bool isImage;
  final ValueChanged<dynamic> onAnswer;

  const ChoiceTemplate({
    Key? key,
    required this.question,
    required this.isImage,
    required this.onAnswer,
  }) : super(key: key);

  @override
  State<ChoiceTemplate> createState() => _ChoiceTemplateState();
}

class _ChoiceTemplateState extends State<ChoiceTemplate> {
  int? _selectedOptionIndex;

  @override
  Widget build(BuildContext context) {
    // We remove 'scale' and assume standard sizing for the board app.
    final double scale = 1.0;
    final double qFz = 32.0 * scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.question.instruction != null) ...[
          Text(widget.question.instruction!,
              style: TextStyle(fontSize: 20.0 * scale, color: AppColors.accent, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.0 * scale),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.volume_up_rounded, color: AppColors.primary, size: qFz),
            SizedBox(width: 16.0 * scale),
            Expanded(
              child: Text(
                widget.question.text,
                style: TextStyle(fontSize: qFz, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.25),
              ),
            ),
          ],
        ),
        if (widget.question.questionImage != null) ...[
          SizedBox(height: 24.0 * scale),
          Container(
            height: 250.0 * scale,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0 * scale),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0 * scale),
              child: Image.asset(
                widget.question.questionImage!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) {
                  return Center(child: Text('Image Loading Error', style: TextStyle(fontSize: 16 * scale)));
                },
              ),
            ),
          ),
        ],
        SizedBox(height: 32.0 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 24.0 * scale,
            mainAxisSpacing: 24.0 * scale,
            mainAxisExtent: 150.0 * scale,
          ),
          itemCount: widget.question.options.length,
          itemBuilder: (context, index) => _buildChoiceOption(widget.question.options[index], index, widget.isImage, scale),
        ),
      ],
    );
  }

  Widget _buildChoiceOption(QuestionOption option, int index, bool isImage, double scale) {
    final isSelected = _selectedOptionIndex == index;
    final labelText = String.fromCharCode(65 + index); // A, B, C, D
    final double ansFz = 28.0 * scale;
    final double labelFz = 16.0 * scale;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedOptionIndex = index);
        widget.onAnswer(option.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16.0 * scale),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.15),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(labelText,
                style: TextStyle(
                    fontSize: labelFz,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white70 : AppColors.textMuted)),
            SizedBox(height: 8.0 * scale),
            Expanded(
              child: Center(
                child: isImage
                    ? (option.value.startsWith('http')
                        ? Image.network(
                            option.value,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image, size: 40),
                          )
                        : Image.asset(
                            option.value,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image, size: 40),
                          ))
                    : Text(
                        option.value,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: ansFz,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Sort Template (two_bucket_sort)
// ----------------------------------------------------------------------
class SortTemplate extends StatefulWidget {
  final QuizQuestion question;
  final ValueChanged<dynamic> onAnswer;

  const SortTemplate({
    Key? key,
    required this.question,
    required this.onAnswer,
  }) : super(key: key);

  @override
  State<SortTemplate> createState() => _SortTemplateState();
}

class _SortTemplateState extends State<SortTemplate> {
  final Map<String, String> _bucketMatches = {};

  void _checkAutoSubmit() {
    if (_bucketMatches.length == widget.question.matchingPairs.length) {
      widget.onAnswer(_bucketMatches);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.question.matchingPairs.map((e) => e.itemB).toSet().toList();
    final items = widget.question.matchingPairs.map((e) => e.itemA).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(widget.question.text,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3)),
            ),
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
          children: items
              .where((i) => !_bucketMatches.containsKey(i))
              .map((i) => Draggable<String>(
                    data: i,
                    feedback: Material(color: Colors.transparent, child: _buildDraggableItem(i, true)),
                    childWhenDragging: Opacity(opacity: 0.3, child: _buildDraggableItem(i, false)),
                    child: _buildDraggableItem(i, false),
                  ))
              .toList(),
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
        _checkAutoSubmit();
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
            border: Border.all(
                color: isHovered ? AppColors.primary : AppColors.primary.withOpacity(0.3), width: isHovered ? 4 : 2),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchedItems
                      .map((i) => GestureDetector(
                            onTap: () => setState(() => _bucketMatches.remove(i)),
                            child: _buildDraggableItem(i, false, small: true),
                          ))
                      .toList(),
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
      child: Text(label,
          style: TextStyle(
              fontSize: small ? 10 : 16,
              fontWeight: FontWeight.bold,
              color: isDragging ? Colors.white : AppColors.textPrimary)),
    );
  }
}

// ----------------------------------------------------------------------
// Match Pairs Template
// ----------------------------------------------------------------------
class MatchPairsTemplate extends StatefulWidget {
  final QuizQuestion question;
  final ValueChanged<dynamic> onAnswer;

  const MatchPairsTemplate({
    Key? key,
    required this.question,
    required this.onAnswer,
  }) : super(key: key);

  @override
  State<MatchPairsTemplate> createState() => _MatchPairsTemplateState();
}

class _MatchPairsTemplateState extends State<MatchPairsTemplate> {
  final Map<String, String> _pairedItems = {};
  String? _selectedMatchLeft;

  void _checkAutoSubmit() {
    if (_pairedItems.length == widget.question.matchingPairs.length) {
      widget.onAnswer(_pairedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leftItems = widget.question.matchingPairs.map((e) => e.itemA).toList();
    final rightItems = widget.question.matchingPairs.map((e) => e.itemB).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(widget.question.text,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3)),
            ),
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
          color: isPaired
              ? AppColors.success.withOpacity(0.2)
              : isSelected
                  ? AppColors.primaryLight
                  : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isPaired
                  ? AppColors.success
                  : isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.2),
              width: isSelected ? 4 : 2),
        ),
        child: Center(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPaired ? AppColors.success : AppColors.textPrimary))),
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
          _checkAutoSubmit();
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
              Text(text,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPaired ? AppColors.success : AppColors.textPrimary)),
              if (isPaired)
                Text('Matched with $pairedLeft',
                    style: const TextStyle(fontSize: 8, color: AppColors.success), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Sequence Template
// ----------------------------------------------------------------------
class SequenceTemplate extends StatefulWidget {
  final QuizQuestion question;
  final ValueChanged<dynamic> onAnswer;

  const SequenceTemplate({
    Key? key,
    required this.question,
    required this.onAnswer,
  }) : super(key: key);

  @override
  State<SequenceTemplate> createState() => _SequenceTemplateState();
}

class _SequenceTemplateState extends State<SequenceTemplate> {
  late List<String> _sequenceItems;

  @override
  void initState() {
    super.initState();
    _sequenceItems = List.from(widget.question.sortedOrder)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.question.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _sequenceItems.removeAt(oldIndex);
              _sequenceItems.insert(newIndex, item);
            });
            widget.onAnswer(_sequenceItems); // Fire onAnswer on any change so `Done` logic can evaluate or autosubmit
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
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_sequenceItems[i],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
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
}

// ----------------------------------------------------------------------
// Voice Response Template (Inert Placeholder)
// ----------------------------------------------------------------------
class VoiceResponseTemplate extends StatefulWidget {
  final QuizQuestion question;
  final ValueChanged<dynamic> onAnswer;

  const VoiceResponseTemplate({
    Key? key,
    required this.question,
    required this.onAnswer,
  }) : super(key: key);

  @override
  State<VoiceResponseTemplate> createState() => _VoiceResponseTemplateState();
}

class _VoiceResponseTemplateState extends State<VoiceResponseTemplate> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.question.text,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.3)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            setState(() => _isRecording = !_isRecording);
            // Just pass a dummy answer so the Done button activates, or auto-submit
            if (_isRecording) widget.onAnswer("recording_started");
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRecording ? 160 : 120,
            height: _isRecording ? 160 : 120,
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.accent : AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: _isRecording ? AppColors.accent : AppColors.primary, width: 4),
              boxShadow: _isRecording
                  ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 30, spreadRadius: 10)]
                  : [],
            ),
            child: Icon(Icons.mic, size: _isRecording ? 80 : 60, color: _isRecording ? Colors.white : AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
        Text(_isRecording ? 'Listening...' : 'Tap to speak',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isRecording ? AppColors.accent : AppColors.textSecondary)),
        if (widget.question.correctAnswers.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('"${widget.question.correctAnswers.first}"',
              style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
        ]
      ],
    );
  }
}
