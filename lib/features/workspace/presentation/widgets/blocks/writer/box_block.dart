import 'dart:io';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/box_block_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/box_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/custom_border_painter.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class BoxBlock extends BaseEditableBlock {
  const BoxBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<BoxBlock> createState() => _BoxBlockState();
}

class _BoxBlockState extends BaseEditableBlockState<BoxBlock> {
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  late Debouncer _saveDebouncer;
  final ImagePicker _imagePicker = ImagePicker();

  double _sliderHeight = 100.0;
  double _overlayOpacity = 0.3;

  @override
  Map<String, dynamic> getDefaultContent() => <String, dynamic>{
    'text': '',
    'backgroundImage': null,
    'overlayOpacity': 0.3,
    'backgroundFit': 'cover',
  };

  @override
  void initializeBlockSpecifics() {
    _textController = TextEditingController(
      text: content['text']?.toString() ?? '',
    );
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 450));
    _overlayOpacity = sanitizeBoxOverlayOpacity(
      content['overlayOpacity'] as num?,
    );
    _sliderHeight = sanitizeBoxHeight(widget.block.style.height);
  }

  @override
  void onContentChanged() {
    final nextText = content['text']?.toString() ?? '';
    if (!_focusNode.hasFocus && _textController.text != nextText) {
      final selectionIndex = _textController.selection.baseOffset.clamp(
        0,
        nextText.length,
      );
      _textController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    }
    _overlayOpacity = sanitizeBoxOverlayOpacity(
      content['overlayOpacity'] as num?,
    );
    _sliderHeight = sanitizeBoxHeight(widget.block.style.height);
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _textController.dispose();
    _focusNode.dispose();
  }

  void _syncContentFromInputs() {
    content['text'] = _textController.text;
    content['overlayOpacity'] = sanitizeBoxOverlayOpacity(_overlayOpacity);
    content['backgroundFit'] = sanitizeBoxBackgroundFit(
      content['backgroundFit'],
    );
  }

  void _persistContent({bool immediate = false}) {
    _syncContentFromInputs();
    if (immediate) {
      saveContent();
    } else {
      _saveDebouncer.call(() => saveContent());
    }
  }

  Future<void> _saveUpdatedStyle(BlockStyle style) async {
    final updatedBlock = widget.block.copyWith(style: style);
    await ref
        .read(editDocumentControllerProvider(widget.docDir).notifier)
        .saveBlock(updatedBlock);
  }

  Future<void> _handleBorderStyleChange(String? newStyle) async {
    if (newStyle == null) return;
    await _saveUpdatedStyle(
      widget.block.style.copyWith(
        borderStyle: sanitizeBoxBorderStyle(newStyle),
      ),
    );
  }

  Future<void> _handleHeightChange(double newHeight) async {
    final safeHeight = sanitizeBoxHeight(newHeight);
    setState(() {
      _sliderHeight = safeHeight;
    });
    await _saveUpdatedStyle(widget.block.style.copyWith(height: safeHeight));
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final extension = image.path.contains('.')
          ? image.path.split('.').last
          : 'jpg';
      final fileName =
          'box_bg_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final targetPath = '${widget.docDir.path}/$fileName';
      await File(image.path).copy(targetPath);

      if (!mounted) return;
      setState(() {
        content['backgroundImage'] = fileName;
      });
      _persistContent(immediate: true);
    } catch (error) {
      showError('Failed to add background image');
    }
  }

  Future<void> _removeBackgroundImage() async {
    final imageName = content['backgroundImage'] as String?;
    if (imageName != null && imageName.isNotEmpty) {
      final file = File('${widget.docDir.path}/$imageName');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }

    if (!mounted) return;
    setState(() {
      content['backgroundImage'] = null;
    });
    _persistContent(immediate: true);
  }

  void _handleOverlayOpacityChange(double opacity) {
    setState(() {
      _overlayOpacity = sanitizeBoxOverlayOpacity(opacity);
    });
  }

  void _handleBackgroundFitChange(String? fit) {
    if (fit == null) return;
    setState(() {
      content['backgroundFit'] = sanitizeBoxBackgroundFit(fit);
    });
    _persistContent(immediate: true);
  }

  Widget? _buildBackgroundImage() {
    final imageName = content['backgroundImage'] as String?;
    if (imageName == null || imageName.isEmpty) return null;

    final imageFile = File('${widget.docDir.path}/$imageName');
    if (!imageFile.existsSync()) {
      return null;
    }

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(imageFile),
            fit: resolveBoxFit(
              sanitizeBoxBackgroundFit(content['backgroundFit']),
            ),
            onError: (_, __) {},
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _overlayOpacity),
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme, String borderStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Box controls',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Background image',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (content['backgroundImage'] != null) ...[
                IconButton(
                  onPressed: _removeBackgroundImage,
                  tooltip: 'Remove image',
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              FilledButton.tonalIcon(
                onPressed: _pickBackgroundImage,
                icon: Icon(
                  content['backgroundImage'] != null
                      ? Icons.change_circle_outlined
                      : Icons.add_photo_alternate_outlined,
                  size: 18,
                ),
                label: Text(
                  content['backgroundImage'] != null ? 'Change' : 'Add',
                ),
              ),
            ],
          ),
          if (content['backgroundImage'] != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: sanitizeBoxBackgroundFit(content['backgroundFit']),
              decoration: const InputDecoration(
                labelText: 'Image fit',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'cover', child: Text('Cover')),
                DropdownMenuItem(value: 'contain', child: Text('Contain')),
                DropdownMenuItem(value: 'fill', child: Text('Fill')),
                DropdownMenuItem(value: 'fitWidth', child: Text('Fit width')),
                DropdownMenuItem(value: 'fitHeight', child: Text('Fit height')),
              ],
              onChanged: _handleBackgroundFitChange,
            ),
            const SizedBox(height: 12),
            Text(
              'Overlay opacity',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _overlayOpacity,
                    max: 0.8,
                    divisions: 16,
                    label: '${(_overlayOpacity * 100).round()}%',
                    onChanged: _handleOverlayOpacityChange,
                    onChangeEnd: (_) => _persistContent(immediate: true),
                  ),
                ),
                Text(
                  '${(_overlayOpacity * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          DropdownButtonFormField<String>(
            initialValue: borderStyle,
            decoration: const InputDecoration(
              labelText: 'Border style',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'normal', child: Text('No border')),
              DropdownMenuItem(value: 'solid', child: Text('Solid')),
              DropdownMenuItem(value: 'dashed', child: Text('Dashed')),
              DropdownMenuItem(value: 'dotted', child: Text('Dotted')),
            ],
            onChanged: _handleBorderStyleChange,
          ),
          const SizedBox(height: 12),
          Text(
            'Minimum height',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _sliderHeight,
                  min: 80.0,
                  max: 600.0,
                  divisions: 52,
                  label: '${_sliderHeight.round()} px',
                  onChanged: (value) {
                    setState(() {
                      _sliderHeight = sanitizeBoxHeight(value);
                    });
                  },
                  onChangeEnd: _handleHeightChange,
                ),
              ),
              Text(
                '${_sliderHeight.round()} px',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    ThemeData theme,
    StyleUtils styleUtils,
    String borderStyle,
  ) {
    final hasBackground =
        (content['backgroundImage'] as String?)?.isNotEmpty ?? false;
    final safeHeight = sanitizeBoxHeight(
      widget.block.style.height ?? _sliderHeight,
    );
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final textAlign = styleUtils.textAlignFromStyle(widget.block.style);
    final alignment = textAlign == TextAlign.center
        ? Alignment.center
        : textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final borderColor =
        styleUtils.parseHex(widget.block.style.borderColor) ??
        theme.colorScheme.primary;
    final borderWidth = widget.block.style.borderWidth.clamp(1.0, 8.0);
    final backgroundColor =
        styleUtils.parseHex(widget.block.style.background) ??
        theme.colorScheme.surfaceContainerLow;
    final textColor = hasBackground
        ? Colors.white
        : styleUtils.parseHex(widget.block.style.color) ??
              theme.colorScheme.onSurface;

    final previewContent = ClipRRect(
      borderRadius: _borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasBackground ? Colors.transparent : backgroundColor,
          gradient: !hasBackground && widget.block.style.background == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerLow.withValues(
                      alpha: 0.95,
                    ),
                    theme.colorScheme.surfaceContainer.withValues(alpha: 0.95),
                  ],
                )
              : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: safeHeight),
          child: Stack(
            children: [
              if (hasBackground) _buildBackgroundImage()!,
              Padding(
                padding: const EdgeInsets.all(18),
                child: Align(
                  alignment: alignment,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textAlign: textAlign,
                    style: styleUtils
                        .applyStyle(widget.block.style)
                        .copyWith(
                          fontSize:
                              widget.block.style.fontSize * textMultiplier,
                          color: textColor,
                          fontStyle: FontStyle.italic,
                          fontWeight: hasBackground
                              ? FontWeight.w600
                              : FontWeight.w400,
                          shadows: hasBackground
                              ? const [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ]
                              : null,
                        ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      hintText: hasBackground
                          ? 'Type overlay text...'
                          : 'Type your callout...',
                      hintStyle: TextStyle(
                        color: hasBackground
                            ? Colors.white.withValues(alpha: 0.75)
                            : theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    onChanged: (_) => _persistContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (borderStyle == 'normal') {
      return previewContent;
    }

    return CustomPaint(
      painter: CustomBorderPainter(
        color: borderColor,
        style: borderStyle,
        strokeWidth: borderWidth,
      ),
      child: previewContent,
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return BoxReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final borderStyle = sanitizeBoxBorderStyle(widget.block.style.borderStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        _buildControlPanel(theme, borderStyle),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: _buildPreview(context, theme, styleUtils, borderStyle),
        ),
      ],
    );
  }
}
