
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/code_reader_block.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/provider/constants_providers.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/code_block_style.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/all.dart';

// Combined widget for editing or reading code content
class CodeBlock extends BaseEditableBlock {
  const CodeBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends BaseEditableBlockState<CodeBlock> {
  late CodeController _codeController;
  final FocusNode _focusNode = FocusNode();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  Map<String, dynamic> getDefaultContent() => {'content': ''};

  @override
  void initializeBlockSpecifics() {
    _codeController = CodeController(
      text: content['content'] ?? '',
      language: _getMode(widget.block.style.language),
    );

    _codeController.addListener(() {
      if (widget.isEditing) {
        _debouncer(() => _saveContentLocal(_codeController.text));
      }
    });
  }

  dynamic _getMode(String? language) {
    if (language == null || language.isEmpty) return null;
    final lang = language.toLowerCase();
    if (lang == 'text') return null;
    return allLanguages[lang]; // null = plain text
  }

  @override
  void onContentChanged() {
    final newText = content['content'] ?? '';
    if (_codeController.text != newText) {
      _codeController.text = newText;
    }
  }

  @override
  void didUpdateWidget(CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sync language updates
    if (oldWidget.block.style.language != widget.block.style.language) {
      _codeController.language = _getMode(widget.block.style.language);
    }
  }

  @override
  void disposeBlockSpecifics() {
    _codeController.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content['content'] ?? ''));
    showSuccess('Code copied!');
  }

  void _saveContentLocal(String value) {
    content['content'] = value;
    saveContent();
  }

  @override
  Widget buildReader(BuildContext context) {
    return CodeReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final styleUtils = ref.read(styleUtilsProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);
    final controller = ref.read(editDocumentControllerProvider(widget.docDir).notifier);

    final backgroundColor =
        styleUtils.parseHex(widget.block.style.background) ?? CodeBlockStyle.background(brightness);
    final headerBackground = CodeBlockStyle.header(brightness);
    final borderColor = CodeBlockStyle.border(brightness);

    final langDisplay = getLanguageDisplayName(widget.block.style.language ?? 'text');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Toolbar(block: widget.block, docDir: widget.docDir),
        // Code editor container with border and rounded corners
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bar: language selector + copy button
              Container(
                color: headerBackground,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showLanguageSelectionDialog(
                        context,
                        supportedLanguages,
                        controller,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.code, color: theme.colorScheme.onSurfaceVariant, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              langDisplay,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant, size: 16),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_outlined, color: theme.colorScheme.onSurfaceVariant, size: 16),
                      tooltip: 'Copy code',
                      onPressed: () => _copyToClipboard(context),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Thin divider
              Divider(height: 1, thickness: 1, color: borderColor),
              // Code editor area
              CodeTheme(
                data: CodeThemeData(
                  styles: brightness == Brightness.dark ? atomOneDarkTheme : atomOneLightTheme,
                ),
                child: CodeField(
                  controller: _codeController,
                  focusNode: _focusNode,
                  enabled: widget.isEditing,
                  readOnly: !widget.isEditing,
                  wrap: false,
                  gutterStyle: CodeBlockStyle.gutterStyle(
                    theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  textStyle: CodeBlockStyle.codeTextStyle(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLanguageSelectionDialog(
    BuildContext context,
    List<String> supportedLanguages,
    EditDocumentController controller,
  ) async {
    final theme = Theme.of(context);
    final currentLanguage = widget.block.style.language ?? 'text';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Select Language',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: supportedLanguages.map((lang) {
                final isSelected = lang == currentLanguage;
                return ListTile(
                  title: Text(
                    getLanguageDisplayName(lang),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  leading: isSelected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  onTap: () async {
                    try {
                      await controller.updateStyle(
                        widget.block,
                        widget.block.style.copyWith(language: lang),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    } catch (e) {
                      showError('Unable to change language. Please try again.');
                    }
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}