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
