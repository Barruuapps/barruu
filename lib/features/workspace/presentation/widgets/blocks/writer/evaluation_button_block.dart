import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/evaluation_button_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class EvaluationButtonBlock extends BaseEditableBlock {
  const EvaluationButtonBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<EvaluationButtonBlock> createState() =>
      _EvaluationButtonBlockState();
}

class _EvaluationButtonBlockState
    extends BaseEditableBlockState<EvaluationButtonBlock> {
  late TextEditingController _buttonTextController;
  late TextEditingController _questionGroupController;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'buttonText': 'Show Results',
    'questionGroup': '',
  };

  @override
  void initializeBlockSpecifics() {
    _buttonTextController = TextEditingController(
      text: content['buttonText']?.toString() ?? 'Show Results',
    );
    _questionGroupController = TextEditingController(
      text: content['questionGroup']?.toString() ?? '',
    );
  }

  @override
  void onContentChanged() {
    if (_buttonTextController.text != content['buttonText']?.toString()) {
      _buttonTextController.text =
          content['buttonText']?.toString() ?? 'Show Results';
    }
    if (_questionGroupController.text != content['questionGroup']?.toString()) {
      _questionGroupController.text =
          content['questionGroup']?.toString() ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _buttonTextController.dispose();
    _questionGroupController.dispose();
  }

  void _saveContentLocal() {
    content['buttonText'] = _buttonTextController.text.trim();
    content['questionGroup'] = _questionGroupController.text.trim();
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return EvaluationButtonReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final textStyle = styleUtils.applyStyle(widget.block.style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Evaluation Button Configuration',
                    style: textStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _buttonTextController,
                style: textStyle,
                decoration: const InputDecoration(
                  labelText: 'Button Text',
                  hintText: 'e.g., Show Results, Calculate Score',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _saveContentLocal(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _questionGroupController,
                style: textStyle,
                decoration: const InputDecoration(
                  labelText: 'Question Group (optional)',
                  hintText: 'Leave empty to evaluate all questions in document',
                  helperText:
                      'Enter group name to evaluate only specific questions',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _saveContentLocal(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calculates scores from submitted questions in read mode',
                        style: textStyle.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Button preview (disabled — shows how the button will look to readers)
              Center(
                child: ElevatedButton.icon(
                  onPressed: null, // disabled preview
                  icon: Icon(
                    Icons.calculate_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  label: Text(
                    _buttonTextController.text.isNotEmpty
                        ? _buttonTextController.text
                        : 'Show Results',
                    style: textStyle.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Preview — button is active in read mode',
                  style: textStyle.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
