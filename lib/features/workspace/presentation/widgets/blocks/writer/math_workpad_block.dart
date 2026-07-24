import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/math_workpad_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MathWorkpadBlock extends BaseEditableBlock {
  const MathWorkpadBlock({
    required super.block,
    required super.docDir,
    required super.isEditing,
    super.key,
  });

  @override
  ConsumerState<MathWorkpadBlock> createState() => _MathWorkpadBlockState();
}

class _MathWorkpadBlockState extends BaseEditableBlockState<MathWorkpadBlock> {
  late TextEditingController _questionController;
  late TextEditingController _explanationController;
  late TextEditingController _solveInputController;
  final List<TextEditingController> _stepControllers = [];
  bool _showSolution = false;
  bool _isSolving = false;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'mode': 'line_order',
    'question': 'Arrange the solution steps to solve the equation:',
    'steps': ['3x - 6 = 9', '3x = 15', 'x = 5'],
    'correctOrder': [0, 1, 2],
    'explanation': 'Add 6 to both sides, then divide by 3.',
    'showSolution': false,
    'referenceSteps': ['3x - 6 = 9', '3x = 15', 'x = 5'],
  };

  @override
  void initializeBlockSpecifics() {
    _questionController = TextEditingController(
      text: content['question']?.toString() ?? '',
    );
    _explanationController = TextEditingController(
      text: content['explanation']?.toString() ?? '',
    );
    _solveInputController = TextEditingController();
    _showSolution = content['showSolution'] as bool? ?? false;

    _loadStepControllers();

    _questionController.addListener(_persistContent);
    _explanationController.addListener(_persistContent);
  }

  void _loadStepControllers() {
    for (final c in _stepControllers) {
      c.removeListener(_persistContent);
      c.dispose();
    }
    _stepControllers.clear();

    final steps =
        ((content['steps'] as List?) ??
                (content['referenceSteps'] as List?) ??
                const <dynamic>[])
            .map((e) => e.toString())
            .toList();

    final normalized = steps.isEmpty ? <String>[''] : steps;
    for (final step in normalized) {
      final ctrl = TextEditingController(text: step);
      ctrl.addListener(_persistContent);
      _stepControllers.add(ctrl);
    }
  }

  @override
  void onContentChanged() {
    if (_questionController.text != (content['question']?.toString() ?? '')) {
      _questionController.text = content['question']?.toString() ?? '';
    }
    if (_explanationController.text !=
        (content['explanation']?.toString() ?? '')) {
      _explanationController.text = content['explanation']?.toString() ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _questionController.dispose();
    _explanationController.dispose();
    _solveInputController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
  }

  void _persistContent() {
    final steps = _stepControllers.map((c) => c.text).toList();

    content['mode'] = 'line_order';
    content['question'] = _questionController.text;
    content['steps'] = steps;
    content['correctOrder'] = List<int>.generate(steps.length, (i) => i);
    content['explanation'] = _explanationController.text;
    content['showSolution'] = _showSolution;
    content['referenceSteps'] = List<String>.from(steps);

    saveContent();
  }

  void _addStep() {
    final ctrl = TextEditingController();
    ctrl.addListener(_persistContent);
    setState(() => _stepControllers.add(ctrl));
    _persistContent();
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) return;
    final ctrl = _stepControllers.removeAt(index);
    ctrl.removeListener(_persistContent);
    ctrl.dispose();
    setState(() {});
    _persistContent();
  }

  void _onReorderSteps(int oldIndex, int newIndex) {
    if (oldIndex == 0 || newIndex == 0) return; // Prevent moving given step
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _stepControllers.removeAt(oldIndex);
      _stepControllers.insert(newIndex, item);
    });
    _persistContent();
  }

  Future<void> _handleAiSolve() async {
    final eq = _solveInputController.text.trim();
    if (eq.isEmpty) return;

    setState(() => _isSolving = true);
    // UI stub for future AI integration (leaves architecture intact without hallucinating methods)
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isSolving = false);
  }

  @override
  Widget buildReader(BuildContext context) {
    return MathWorkpadReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outline.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeTransition(
            opacity: toolbarOpacity,
            child: Toolbar(block: widget.block, docDir: widget.docDir),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _questionController,
            minLines: 1,
            maxLines: 3,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Type instruction (e.g. Order the steps...)',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Auto-Solve UI Stub
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _solveInputController,
                    decoration: const InputDecoration(
                      hintText: 'Equation to auto-solve (e.g. 2x + 4 = 10)',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleAiSolve(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSolving ? null : _handleAiSolve,
                  icon: _isSolving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isSolving ? 'Solving...' : 'Auto-Solve'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'EQUATION STEPS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stepControllers.length,
            onReorder: _onReorderSteps,
            itemBuilder: (context, index) =>
                _buildStepEditorRow(theme, index, outlineColor),
          ),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addStep,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Step'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(style: BorderStyle.solid, color: outlineColor),
            ),
          ),
          const SizedBox(height: 16),

          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Quiz Settings',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              leading: const Icon(Icons.settings_outlined, size: 20),
              tilePadding: EdgeInsets.zero,
              children: [
                TextField(
                  controller: _explanationController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Global Explanation',
                    hintText: 'Explain the logic shown after completion...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Show solution to student',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _showSolution,
                  onChanged: (v) {
                    setState(() => _showSolution = v);
                    _persistContent();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepEditorRow(ThemeData theme, int index, Color outlineColor) {
    final ctrl = _stepControllers[index];
    final isGiven = index == 0;

    return Container(
      key: ValueKey('${ctrl.hashCode}_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outlineColor),
      ),
      child: Row(
        children: [
          Icon(
            isGiven ? Icons.check_box_outline_blank : Icons.drag_indicator,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: isGiven ? 'Given Equation...' : 'Next step...',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: _buildMathPreview(ctrl.text.trim(), theme),
          ),
          if (!isGiven && _stepControllers.length > 2)
            IconButton(
              onPressed: () => _removeStep(index),
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildMathPreview(String latex, ThemeData theme) {
    if (latex.isEmpty) return const SizedBox.shrink();
    try {
      return Math.tex(
        latex,
        textStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
        onErrorFallback: (e) => Text(latex, overflow: TextOverflow.ellipsis),
      );
    } catch (_) {
      return Text(latex, overflow: TextOverflow.ellipsis);
    }
  }
}
