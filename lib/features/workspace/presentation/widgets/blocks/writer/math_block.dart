

import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/math_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/math_controls.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathBlock extends BaseEditableBlock {
  const MathBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<MathBlock> createState() => _MathBlockState();
}

class _MathBlockState extends BaseEditableBlockState<MathBlock> {
  late TextEditingController _latexController;
  late TextEditingController _captionController;
  final FocusNode _focusNode = FocusNode();

  @override
  Map<String, dynamic> getDefaultContent() => {
    'latex': '',
    'caption': '',
  };

  @override
  void initializeBlockSpecifics() {
    _latexController = TextEditingController(text: content['latex'] ?? '');
    _captionController = TextEditingController(text: content['caption'] ?? '');
  }

  @override
  void onContentChanged() {
    if (_latexController.text != content['latex']) {
      _latexController.text = content['latex'] ?? '';
    }
    if (_captionController.text != content['caption']) {
      _captionController.text = content['caption'] ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _latexController.dispose();
    _captionController.dispose();
    _focusNode.dispose();
  }

  void _saveContentLocal() {
    content['latex'] = _latexController.text;
    content['caption'] = _captionController.text;
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return MathReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final color = styleUtils.parseHex(widget.block.style.color) ?? theme.colorScheme.onSurface;
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(
            block: widget.block,
            docDir: widget.docDir,
            child: MathControls(
              controller: ref.read(editDocumentControllerProvider(widget.docDir).notifier),
              block: widget.block,
              latexController: _latexController,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview of equations
              if (_latexController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: _getCrossAxisAlignment(textAlign),
                    children: _parseEquations(_latexController.text).map((equation) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Math.tex(
                            equation,
                            textStyle: styleUtils.applyStyle(widget.block.style).copyWith(
                              fontSize: (styleUtils.applyStyle(widget.block.style).fontSize ?? 16) * 1.1,
                              color: color,
                            ),
                            onErrorFallback: (FlutterMathException e) => Text(
                              "Invalid: ${equation.length > 30 ? '${equation.substring(0, 30)}...' : equation}",
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              TextField(
                controller: _latexController,
                focusNode: _focusNode,
                maxLines: null,
                style: styleUtils.applyStyle(widget.block.style).copyWith(
                  fontFamily: 'Roboto Mono',
                  color: color,
                  fontSize: (styleUtils.applyStyle(widget.block.style).fontSize ?? 16) * 0.9,
                ),
                textAlign: textAlign,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type LaTeX math... One equation per line (e.g., E = mc^2)',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                    fontSize: (styleUtils.applyStyle(widget.block.style).fontSize ?? 16) * 0.9,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                onChanged: (value) => _saveContentLocal(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                maxLines: null,
                minLines: 1,
                style: styleUtils.applyStyle(widget.block.style).copyWith(
                  fontStyle: FontStyle.italic,
                  fontSize: (styleUtils.applyStyle(widget.block.style).fontSize ?? 16) * 0.85,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: textAlign,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add an optional caption...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                    fontSize: (styleUtils.applyStyle(widget.block.style).fontSize ?? 16) * 0.85,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) => _saveContentLocal(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _parseEquations(String latex) {
    if (latex.isEmpty) return [];
    return latex.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  CrossAxisAlignment _getCrossAxisAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      case TextAlign.justify:
      case TextAlign.start:
      case TextAlign.end:
      case TextAlign.left:
      default:
        return CrossAxisAlignment.start;
    }
  }
}