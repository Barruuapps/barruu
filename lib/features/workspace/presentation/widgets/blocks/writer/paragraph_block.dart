import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/paragraph_reader_block.dart';
import 'package:barruu/features/workspace/presentation/services/image_file_service.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/paragraph_controls.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/core/utils/app_logger.dart';

class ParagraphBlock extends BaseEditableBlock {
  const ParagraphBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<ParagraphBlock> createState() =>
      _ParagraphBlockState();
}

class _ParagraphBlockState
    extends BaseEditableBlockState<ParagraphBlock> {
  // Block-specific state (only what's unique to paragraph blocks)
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  
  // Debouncer to prevent excessive save operations during rapid typing
  late Debouncer _saveDebouncer;

  final ImageFileService _imageFileService = ImageFileService();

  // Define default content structure for paragraph blocks
  @override
  Map<String, dynamic> getDefaultContent() => {'content': ''};

  // Initialize paragraph-specific resources
  @override
  void initializeBlockSpecifics() {
    _textController = TextEditingController(text: content['content'] ?? '');
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  }

  // Dispose paragraph-specific resources
  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _textController.dispose();
    _focusNode.dispose();
  }

  // React to content changes
  @override
  void onContentChanged() {
    // Update text controller when content changes externally
    if (_textController.text != (content['content'] ?? '')) {
      _textController.text = content['content'] ?? '';
    }
  }

  bool get _isImageTemplate {
    final t = widget.block.style.paragraphTemplate;
    return t == 'image_left' || t == 'image_right' ||
        t == 'image_float_left' || t == 'image_float_right';
  }

  Future<void> _pickImage(BuildContext context) async {
    try {
      final images = await _imageFileService.pickAndSaveImages(widget.docDir);
      if (images != null && images.isNotEmpty) {
        content['imagePath'] = images.first['path'];
        content['imageType'] = images.first['type'];
        saveContent();
        if (mounted) setState(() {});
      }
    } catch (e, stackTrace) {
      logger.e('Failed to pick image for paragraph', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _enterNetworkImageUrl(BuildContext context) async {
    final controller = TextEditingController(
      text: content['imagePath'] as String? ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://...',
            labelText: 'Image URL',
          ),
          autofocus: true,
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      content['imagePath'] = result;
      content['imageType'] = 'network';
      saveContent();
      if (mounted) setState(() {});
    }
  }

  // Build editing UI
  @override
  Widget buildEditor(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final controller =
        ref.read(editDocumentControllerProvider(widget.docDir).notifier);
    final theme = Theme.of(context);

    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 24.0 : (isWide ? 16.0 : 0.0);
    final verticalPadding = isDesktop ? 14.0 : (isWide ? 10.0 : 6.0);
    final padding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final lineHeight = ResponsiveUtils.getLineHeight(context);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity, // From base class
          child: Toolbar(
            block: widget.block,
            docDir: widget.docDir,
            child: ParagraphControls(
              controller: controller,
              block: widget.block,
              textController: _textController,
            ),
          ),
        ),
        // Image picker row for image_left / image_right templates
        if (_isImageTemplate)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 4,
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(context),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Pick Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _enterNetworkImageUrl(context),
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Image URL'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
                if (content['imagePath'] != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Remove image',
                    onPressed: () {
                      content.remove('imagePath');
                      content.remove('imageType');
                      saveContent();
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getBorderRadius(context, baseRadius: 10.0),
            ),
            color: styleUtils.parseHex(widget.block.style.background),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: null,
            style: styleUtils.applyStyle(widget.block.style).copyWith(
                  fontSize: fontSize * textMultiplier,
                  color: color,
                  height: lineHeight,
                ),
            textAlign: styleUtils.textAlignFromStyle(widget.block.style),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Type something...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            onChanged: (value) {
              content['content'] = value;
              // Debounce save to prevent excessive I/O during rapid typing
              _saveDebouncer.call(() => saveContent());
            },
          ),
        ),
      ],
    );
  }

  // Build read-only UI
  @override
  Widget buildReader(BuildContext context) {
    return ParagraphReaderBlock(
      block: widget.block,
      allowSelection: false,
      docDir: widget.docDir,
    );
  }
}
