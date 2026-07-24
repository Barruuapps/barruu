import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/block_quote_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/blockquote_template_selector.dart';
import 'package:barruu/features/workspace/constants/quote_types.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// Constants for decorative accent heights
const double _kMinAccentHeightSmall = 60.0;
const double _kMinAccentHeightLarge = 100.0;

/// Enhanced BlockQuote widget with admonition support (note, tip, warning, danger, success, info)
/// and optional author/avatar attribution. Extends BaseEditableBlock.
class BlockQuoteBlock extends BaseEditableBlock {
  const BlockQuoteBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<BlockQuoteBlock> createState() => _BlockQuoteBlockState();
}

class _BlockQuoteBlockState extends BaseEditableBlockState<BlockQuoteBlock> {
  // Block-specific state
  late TextEditingController _textController;
  late TextEditingController _authorController;
  late TextEditingController _avatarUrlController;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _authorFocusNode = FocusNode();
  late Debouncer _saveDebouncer;
  bool _showAuthorField = false;
  bool _showAvatarUrlInput = false;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  Map<String, dynamic> getDefaultContent() => {'content': '', 'author': ''};

  @override
  void initializeBlockSpecifics() {
    _textController = TextEditingController(text: content['content'] ?? '');
    _authorController = TextEditingController(text: content['author'] ?? '');
    _avatarUrlController = TextEditingController();
    _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _showAuthorField = (content['author'] as String?)?.isNotEmpty == true ||
        widget.block.style.authorName?.isNotEmpty == true ||
        widget.block.style.authorAvatar?.isNotEmpty == true;
  }

  @override
  void disposeBlockSpecifics() {
    _saveDebouncer.dispose();
    _textController.dispose();
    _authorController.dispose();
    _avatarUrlController.dispose();
    _focusNode.dispose();
    _authorFocusNode.dispose();
  }

  @override
  void onContentChanged() {
    if (_textController.text != (content['content'] ?? '')) {
      _textController.text = content['content'] ?? '';
    }
    if (_authorController.text != (content['author'] ?? '')) {
      _authorController.text = content['author'] ?? '';
    }
  }

  void _saveQuoteContent() {
    content['content'] = _textController.text;
    content['author'] = _authorController.text;
    _saveDebouncer.call(() => saveContent());
  }

  void _updateQuoteType(String type) {
    final updatedBlock = widget.block.copyWith(
      style: widget.block.style.copyWith(quoteType: type),
    );
    ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);
  }

  void _updateQuoteTemplate(String template) {
    final updatedBlock = widget.block.copyWith(
      style: widget.block.style.copyWith(quoteTemplate: template),
    );
    ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);
  }

  void _validateAndPromptForAuthor() {
    if (_authorController.text.trim().isEmpty) {
      setState(() {
        _showAuthorField = true;
      });
      showError('Please enter an author name for the avatar');
      _authorFocusNode.requestFocus();
    }
  }

  void _updateAvatarUrl(String url) {
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      showError('Please enter a valid URL starting with http:// or https://');
      return;
    }

    _validateAndPromptForAuthor();

    final updatedBlock = widget.block.copyWith(
      style: widget.block.style.copyWith(authorAvatar: url),
    );
    ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);

    setState(() {
      _showAvatarUrlInput = false;
      _avatarUrlController.clear();
    });

    showSuccess('Avatar image added');
  }

  Future<void> _pickLocalAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 200,
        maxHeight: 200,
      );

      if (picked == null) return;

      _validateAndPromptForAuthor();

      final avatarsDir = Directory('${widget.docDir.path}/media/avatars');
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      final fileName = picked.name;
      final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
      final uniqueName = '${_uuid.v4()}_$sanitizedName';
      final newPath = '${avatarsDir.path}/$uniqueName';

      await File(picked.path).copy(newPath);

      final updatedBlock = widget.block.copyWith(
        style: widget.block.style.copyWith(authorAvatar: 'media/avatars/$uniqueName'),
      );
      ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);

      showSuccess('Avatar image added');
    } catch (e) {
      if (mounted) {
        showError('Error adding avatar: $e');
      }
    }
  }

  void _removeAvatar() {
    final updatedBlock = widget.block.copyWith(
      style: widget.block.style.copyWith(authorAvatar: ''),
    );
    ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);
    showSuccess('Avatar removed');
  }

  void _showAvatarSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Avatar Image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.link, color: theme.colorScheme.primary),
                  title: const Text('From URL'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _showAvatarUrlInput = true;
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
                  title: const Text('From Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickLocalAvatar();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarWidget(String? avatarPath, ThemeData theme, {double size = 40}) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: ShimmerLoading(
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final file = File('${widget.docDir.path}/$avatarPath');
    if (file.existsSync()) {
      return ClipOval(
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => CircleAvatar(
            radius: size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildQuoteTypeSelector(ThemeData theme, String quoteType) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QuoteTypes.all.map((config) {
          final isSelected = quoteType == config.type;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(config.icon, size: 16),
                  const SizedBox(width: 4),
                  Text(config.label),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) _updateQuoteType(config.type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final quoteType = widget.block.style.quoteType ?? 'quote';
    final quoteTemplate = widget.block.style.quoteTemplate ?? 'basic';
    final config = QuoteTypes.getConfig(quoteType);

    final fontSize = widget.block.style.fontSize;
    final borderColor = styleUtils.parseHex(widget.block.style.borderColor) ?? config.getBorderColor(isDark);
    final backgroundColor = styleUtils.parseHex(widget.block.style.background) ?? config.getBackgroundColor(isDark);
    final iconColor = config.getIconColor(isDark);
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final horizontalPadding = isDesktop ? 20.0 : (isWide ? 16.0 : 8.0);
    final verticalPadding = isDesktop ? 16.0 : (isWide ? 12.0 : 8.0);
    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final margin = EdgeInsets.symmetric(vertical: verticalMargin);
    final lineHeight = ResponsiveUtils.getLineHeight(context, baseHeight: 1.5);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Column(
            children: [
              Toolbar(block: widget.block, docDir: widget.docDir),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: _buildQuoteTypeSelector(theme, quoteType)),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BlockquoteTemplateSelector(
                            selectedTemplate: quoteTemplate,
                            onTemplateSelected: (template) {
                              _updateQuoteTemplate(template);
                              Navigator.of(context).pop();
                            },
                            theme: theme,
                          ),
                        );
                      },
                      icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                      label: const Text('Style'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildTemplateContent(
          context,
          theme,
          styleUtils,
          quoteTemplate,
          config,
          borderColor,
          backgroundColor,
          iconColor,
          color,
          fontSize,
          textMultiplier,
          lineHeight,
          horizontalPadding,
          verticalPadding,
          margin,
        ),
      ],
    );
  }

  Widget _buildTemplateContent(
    BuildContext context,
    ThemeData theme,
    StyleUtils styleUtils,
    String template,
    QuoteTypeConfig config,
    Color borderColor,
    Color backgroundColor,
    Color iconColor,
    Color color,
    double fontSize,
    double textMultiplier,
    double lineHeight,
    double horizontalPadding,
    double verticalPadding,
    EdgeInsets margin,
  ) {
    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
    
    switch (template) {
      case 'bordered':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          padding: padding,
          child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
        );
      case 'highlighted':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.6),
                theme.colorScheme.secondaryContainer.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: padding,
          child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
        );
      case 'modern':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: horizontalPadding - 8, top: verticalPadding),
                child: Container(
                  width: 3,
                  constraints: const BoxConstraints(minHeight: _kMinAccentHeightSmall),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [borderColor, theme.colorScheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
                ),
              ),
            ],
          ),
        );
      case 'testimonial':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.format_quote, color: iconColor.withOpacity(0.5), size: 28),
              const SizedBox(height: 6),
              _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
            ],
          ),
        );
      case 'callout':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: theme.colorScheme.onPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
              ),
            ],
          ),
        );
      case 'sidebar':
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                constraints: const BoxConstraints(minHeight: _kMinAccentHeightLarge),
                margin: margin,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: margin,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: padding,
                  child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
                ),
              ),
            ],
          ),
        );
      case 'featured':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.2),
                theme.colorScheme.tertiary.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(IconsaxPlusBold.quote_up, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
              ),
            ],
          ),
        );
      case 'card':
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
            ],
          ),
        );
      case 'basic':
      default:
        return Container(
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: horizontalPadding - 8, top: verticalPadding),
                child: Icon(config.icon, color: iconColor, size: 24),
              ),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: _buildQuoteContent(context, theme, styleUtils, config, iconColor, color, fontSize, textMultiplier, lineHeight, horizontalPadding, verticalPadding),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildQuoteContent(
    BuildContext context,
    ThemeData theme,
    StyleUtils styleUtils,
    QuoteTypeConfig config,
    Color iconColor,
    Color color,
    double fontSize,
    double textMultiplier,
    double lineHeight,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: null,
          style: styleUtils.applyStyle(widget.block.style).copyWith(
            fontSize: fontSize * textMultiplier,
            color: color,
            height: lineHeight,
            fontStyle: FontStyle.italic,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            hintText: 'Type your ${config.label.toLowerCase()}...',
            hintStyle: TextStyle(color: color.withOpacity(0.5)),
          ),
          onChanged: (value) => _saveQuoteContent(),
        ),
        if (_showAuthorField || widget.block.style.authorAvatar?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.block.style.authorAvatar?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildAvatarWidget(widget.block.style.authorAvatar, theme, size: 32),
                ),
              Expanded(
                child: TextField(
                  controller: _authorController,
                  focusNode: _authorFocusNode,
                  style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: '— Author name',
                    hintStyle: TextStyle(color: color.withOpacity(0.5)),
                    prefixText: '— ',
                    prefixStyle: TextStyle(color: color.withOpacity(0.8)),
                  ),
                  onChanged: (value) => _saveQuoteContent(),
                ),
              ),
            ],
          ),
        ],
        if (_showAvatarUrlInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(
                    hintText: 'Enter avatar URL (https://...)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _updateAvatarUrl,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _updateAvatarUrl(_avatarUrlController.text),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showAvatarUrlInput = false;
                    _avatarUrlController.clear();
                  });
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_showAuthorField)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAuthorField = true;
                  });
                },
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Author', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
            if (widget.block.style.authorAvatar?.isEmpty ?? true)
              TextButton.icon(
                onPressed: _showAvatarSourceDialog,
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: const Text('Add Avatar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              )
            else
              TextButton.icon(
                onPressed: _removeAvatar,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove Avatar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildReader(BuildContext context) {
    return BlockQuoteReaderBlock(block: widget.block, docDir: widget.docDir, allowSelection: false);
  }
}

