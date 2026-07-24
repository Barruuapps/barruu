import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/chat_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class ChatBlock extends BaseEditableBlock {
  const ChatBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ChatBlock> createState() => _ChatBlockState();
}

class _ChatBlockState extends BaseEditableBlockState<ChatBlock> {
  late TextEditingController _textController;
  late TextEditingController _profileNameController;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _profileFocusNode = FocusNode();

  @override
  Map<String, dynamic> getDefaultContent() => {
    'message': '',
    'profileName': '',
  };

  @override
  void initializeBlockSpecifics() {
    _textController = TextEditingController(
      text: content['message']?.toString() ?? '',
    );
    _profileNameController = TextEditingController(
      text: content['profileName']?.toString() ?? '',
    );
  }

  @override
  void onContentChanged() {
    if (_textController.text != content['message']?.toString()) {
      _textController.text = content['message']?.toString() ?? '';
    }
    if (_profileNameController.text != content['profileName']?.toString()) {
      _profileNameController.text = content['profileName']?.toString() ?? '';
    }
  }

  @override
  void disposeBlockSpecifics() {
    _textController.dispose();
    _profileNameController.dispose();
    _focusNode.dispose();
    _profileFocusNode.dispose();
  }

  void _handleAlignChange() {
    final newAlign = widget.block.style.align == 'right' ? 'left' : 'right';
    final updatedStyle = widget.block.style.copyWith(align: newAlign);
    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    ref
        .read(editDocumentControllerProvider(widget.docDir).notifier)
        .saveBlock(updatedBlock);
  }

  void _saveContentLocal() {
    final profileName = _profileNameController.text.trim();

    content['message'] = _textController.text.trim();
    content['profileName'] = profileName;
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return ChatReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final isRight = widget.block.style.align == 'right';
    final backgroundColor =
        styleUtils.parseHex(widget.block.style.background) ??
        (isRight
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.secondaryContainer.withValues(alpha: 0.8));
    final textColor =
        styleUtils.parseHex(widget.block.style.color) ??
        (isRight
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        const SizedBox(height: 8),

        // Control panel with profile name and alignment
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _profileNameController,
                    focusNode: _profileFocusNode,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      hintText: 'Profile name (optional)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) => _saveContentLocal(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isRight
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      color: isRight
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      semanticLabel: isRight ? 'Align left' : 'Align right',
                    ),
                    tooltip: isRight ? 'Align left' : 'Align right',
                    onPressed: _handleAlignChange,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Message input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRight
                    ? theme.colorScheme.primary.withOpacity(0.3)
                    : theme.colorScheme.secondaryContainer.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 3,
              style: styleUtils
                  .applyStyle(widget.block.style)
                  .copyWith(
                    fontSize: widget.block.style.fontSize,
                    color: textColor,
                    height: 1.4,
                  ),
              textAlign: styleUtils.textAlignFromStyle(widget.block.style),
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                hintStyle: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                semanticCounterText: 'Chat message input',
              ),
              onChanged: (value) => _saveContentLocal(),
            ),
          ),
        ),
      ],
    );
  }
}
