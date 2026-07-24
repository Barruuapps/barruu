import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/spacer_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:flutter/material.dart';

class SpacerBlock extends BaseEditableBlock {
  const SpacerBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  BaseEditableBlockState<SpacerBlock> createState() => _SpacerBlockState();
}

class _SpacerBlockState extends BaseEditableBlockState<SpacerBlock> {
  static const double _minHeight = 8.0;
  static const double _maxHeight = 240.0;
  double _height = 24.0;

  @override
  Map<String, dynamic> getDefaultContent() => {'height': 24.0};

  @override
  void initializeBlockSpecifics() {
    _height = _resolveHeight();
  }

  @override
  void onContentChanged() {
    _height = _resolveHeight();
  }

  double _resolveHeight() {
    if (widget.block.style.height != null && widget.block.style.height! > 0) {
      return widget.block.style.height!;
    }
    final contentHeight = (content['height'] as num?)?.toDouble();
    if (contentHeight != null && contentHeight > 0) {
      return contentHeight;
    }
    return 24.0;
  }

  Future<void> _saveHeight(double value) async {
    setState(() {
      _height = value;
      content['height'] = value;
    });
    await saveContent();
    final updatedStyle = widget.block.style.copyWith(height: value);
    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    await ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);
  }

  @override
  Widget buildReader(BuildContext context) {
    return SpacerReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                height: _height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.45),
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Spacer height'),
                  Expanded(
                    child: Slider(
                      value: _height.clamp(_minHeight, _maxHeight),
                      min: _minHeight,
                      max: _maxHeight,
                      divisions: 58,
                      label: '${_height.round()} px',
                      onChanged: (value) => setState(() => _height = value),
                      onChangeEnd: _saveHeight,
                    ),
                  ),
                  Text('${_height.round()} px'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
