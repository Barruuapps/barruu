import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/provider/constants_providers.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/code_block_style.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/all.dart';

// Reader widget for displaying code content
class CodeReaderBlock extends ConsumerStatefulWidget {
  final Block block;

  const CodeReaderBlock({super.key, required this.block});

  @override
  ConsumerState<CodeReaderBlock> createState() => _CodeReaderBlockState();
}

class _CodeReaderBlockState extends ConsumerState<CodeReaderBlock> {
  late CodeController _codeController;
  late Map<String, dynamic> _content;

  dynamic _getMode(String? language) {
    if (language == null || language.isEmpty) return null;
    final lang = language.toLowerCase();
    if (lang == 'text') return null;
    return allLanguages[lang];
  }

  @override
  void initState() {
    super.initState();
    _content = _parseContent();
    _codeController = CodeController(
      text: _content['content'] ?? '',
      language: _getMode(widget.block.style.language),
    );
  }

  Map<String, dynamic> _parseContent() {
    Map<String, dynamic> content = {'content': ''};
    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
        content['content'] ??= '';
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block content',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return content;
  }

  @override
  void didUpdateWidget(CodeReaderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      _content = _parseContent();
      _codeController.text = _content['content'] ?? '';
    }
    if (oldWidget.block.style.language != widget.block.style.language) {
      _codeController.language = _getMode(widget.block.style.language);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _content['content'] ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final brightness = theme.brightness;
    final userBackground = styleUtils.parseHex(widget.block.style.background);
    final langDisplay = getLanguageDisplayName(
      widget.block.style.language ?? 'text',
    );
    final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
    final radius = ResponsiveUtils.getPlatformRadius(context, baseRadius: 8.0);
    final template = widget.block.style.codeTemplate ?? 'minimal';

    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      child: _buildTemplate(
        context,
        template: template,
        theme: theme,
        brightness: brightness,
        userBackground: userBackground,
        langDisplay: langDisplay,
        radius: radius,
      ),
    );
  }

  Widget _buildTemplate(
    BuildContext context, {
    required String template,
    required ThemeData theme,
    required Brightness brightness,
    required Color? userBackground,
    required String langDisplay,
    required double radius,
  }) {
    switch (template) {
      case 'minimal':
        return _buildMinimalTemplate(
          context,
          theme: theme,
          brightness: brightness,
          userBackground: userBackground,
          radius: radius,
        );
      case 'card':
        return _buildCardTemplate(
          context,
          theme: theme,
          brightness: brightness,
          userBackground: userBackground,
          langDisplay: langDisplay,
          radius: radius,
        );
      case 'terminal':
        return _buildTerminalTemplate(
          context,
          theme: theme,
          brightness: brightness,
          langDisplay: langDisplay,
          radius: radius,
        );
      case 'github':
        return _buildGithubTemplate(
          context,
          theme: theme,
          brightness: brightness,
          langDisplay: langDisplay,
          radius: radius,
        );
      case 'dracula':
        return _buildDraculaTemplate(context, radius: radius);
      case 'monokai':
        return _buildMonokaiTemplate(context, radius: radius);
      case 'vscode':
        return _buildVscodeTemplate(context, radius: radius);
      case 'bordered':
        return _buildBorderedTemplate(
          context,
          theme: theme,
          brightness: brightness,
          userBackground: userBackground,
          langDisplay: langDisplay,
          radius: radius,
        );
      case 'default':
      default:
        return _buildDefaultTemplate(
          context,
          theme: theme,
          brightness: brightness,
          userBackground: userBackground,
          langDisplay: langDisplay,
          radius: radius,
        );
    }
  }

  // ── Minimal: no header bar, just code with subtle background ─────────────

  Widget _buildMinimalTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required Color? userBackground,
    required double radius,
  }) {
    final backgroundColor =
        userBackground ?? CodeBlockStyle.background(brightness);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          CodeTheme(
            data: CodeThemeData(
              styles: brightness == Brightness.dark
                  ? atomOneDarkTheme
                  : atomOneLightTheme,
            ),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              textStyle: CodeBlockStyle.codeTextStyle(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: ResponsiveUtils.ensureTouchTarget(
              IconButton(
                icon: Icon(
                  Icons.copy_outlined,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                  size: 14,
                ),
                tooltip: 'Copy code',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _copyToClipboard(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Default: header bar with language + copy button ──────────────────────

  Widget _buildDefaultTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required Color? userBackground,
    required String langDisplay,
    required double radius,
  }) {
    final backgroundColor =
        userBackground ?? CodeBlockStyle.background(brightness);
    final headerBackground = CodeBlockStyle.header(brightness);
    final borderColor = CodeBlockStyle.border(brightness);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDefaultHeader(
            context,
            theme: theme,
            langDisplay: langDisplay,
            headerBackground: headerBackground,
            borderColor: borderColor,
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          _buildCodeField(brightness),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader(
    BuildContext context, {
    required ThemeData theme,
    required String langDisplay,
    required Color headerBackground,
    required Color borderColor,
  }) {
    return Container(
      color: headerBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code,
                color: theme.colorScheme.onSurfaceVariant,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                langDisplay,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: PlatformThemeHelper.isAndroid
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          ResponsiveUtils.ensureTouchTarget(
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
              tooltip: 'Copy code',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () {
                HapticFeedback.selectionClick();
                _copyToClipboard(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Card: elevated card with shadow and accent header ────────────────────

  Widget _buildCardTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required Color? userBackground,
    required String langDisplay,
    required double radius,
  }) {
    final backgroundColor =
        userBackground ?? CodeBlockStyle.background(brightness);
    final borderColor = CodeBlockStyle.border(brightness);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code,
                      color: theme.colorScheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      langDisplay,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                ResponsiveUtils.ensureTouchTarget(
                  IconButton(
                    icon: Icon(
                      Icons.copy_outlined,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    tooltip: 'Copy code',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _copyToClipboard(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          _buildCodeField(brightness),
        ],
      ),
    );
  }

  // ── Terminal: dark background with macOS traffic-light dots ──────────────

  Widget _buildTerminalTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required String langDisplay,
    required double radius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: const Color(0xFF2A2A3C),
            child: Row(
              children: [
                _terminalDot(const Color(0xFFFF5F57)),
                const SizedBox(width: 5),
                _terminalDot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 5),
                _terminalDot(const Color(0xFF28CA41)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    langDisplay,
                    style: const TextStyle(
                      color: Color(0xFFABB2BF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: Color(0xFFABB2BF),
                    size: 16,
                  ),
                  tooltip: 'Copy code',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyToClipboard(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFF3A3A4C)),
          // Always use dark theme for terminal
          CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(
                const Color(0xFFABB2BF).withValues(alpha: 0.4),
              ),
              textStyle: CodeBlockStyle.codeTextStyle().copyWith(
                color: const Color(0xFFABB2BF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ── GitHub: GitHub-inspired grey header ───────────────────────────────────

  Widget _buildGithubTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required String langDisplay,
    required double radius,
  }) {
    const githubBg = Color(0xFFF6F8FA);
    const githubHeaderBg = Color(0xFFEAECF0);
    const githubBorder = Color(0xFFD0D7DE);
    const githubText = Color(0xFF24292F);

    return Container(
      decoration: BoxDecoration(
        color: githubBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: githubBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: githubHeaderBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: githubBorder),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        langDisplay,
                        style: const TextStyle(
                          color: githubText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: githubText,
                    size: 16,
                  ),
                  tooltip: 'Copy code',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyToClipboard(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: githubBorder),
          CodeTheme(
            data: CodeThemeData(styles: atomOneLightTheme),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(
                const Color(0xFF24292F).withValues(alpha: 0.4),
              ),
              textStyle: CodeBlockStyle.codeTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bordered: thick primary left-border accent ────────────────────────────

  Widget _buildBorderedTemplate(
    BuildContext context, {
    required ThemeData theme,
    required Brightness brightness,
    required Color? userBackground,
    required String langDisplay,
    required double radius,
  }) {
    final backgroundColor =
        userBackground ?? CodeBlockStyle.background(brightness);
    final borderColor = CodeBlockStyle.border(brightness);

    // ClipRRect handles rounded corners so BoxDecoration can use a
    // non-uniform Border (different left accent colour) without throwing
    // "borderRadius can only be given on borders with uniform colors".
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 4),
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        color: theme.colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        langDisplay,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  ResponsiveUtils.ensureTouchTarget(
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      tooltip: 'Copy code',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _copyToClipboard(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildCodeField(brightness),
          ],
        ),
      ),
    );
  }

  // ── Shared code field builder ─────────────────────────────────────────────

  Widget _buildCodeField(Brightness brightness) {
    return CodeTheme(
      data: CodeThemeData(
        styles: brightness == Brightness.dark
            ? atomOneDarkTheme
            : atomOneLightTheme,
      ),
      child: CodeField(
        controller: _codeController,
        enabled: false,
        readOnly: true,
        wrap: false,
        gutterStyle: GutterStyle(
          showLineNumbers: false,
          showErrors: false,
          showFoldingHandles: false,
          width: 0,
        ),
        textStyle: CodeBlockStyle.codeTextStyle(),
      ),
    );
  }

  // ── Dracula: dark purple-accented theme ───────────────────────────────────

  Widget _buildDraculaTemplate(BuildContext context, {required double radius}) {
    const bg = Color(0xFF282A36);
    const header = Color(0xFF21222C);
    const border = Color(0xFF44475A);
    const accent = Color(0xFFBD93F9);
    const textColor = Color(0xFFF8F8F2);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: header,
            child: Row(
              children: [
                const Icon(Icons.circle, color: accent, size: 8),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    getLanguageDisplayName(
                      widget.block.style.language ?? 'text',
                    ),
                    style: const TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: textColor,
                    size: 16,
                  ),
                  tooltip: 'Copy code',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyToClipboard(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: border),
          CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(const Color(0xFF6272A4)),
              textStyle: CodeBlockStyle.codeTextStyle().copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monokai: warm dark olive theme ────────────────────────────────────────

  Widget _buildMonokaiTemplate(BuildContext context, {required double radius}) {
    const bg = Color(0xFF272822);
    const header = Color(0xFF1D1E1A);
    const border = Color(0xFF3E3D32);
    const accent = Color(0xFFA6E22E);
    const textColor = Color(0xFFF8F8F2);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: header,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    getLanguageDisplayName(
                      widget.block.style.language ?? 'text',
                    ),
                    style: const TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: textColor,
                    size: 16,
                  ),
                  tooltip: 'Copy code',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyToClipboard(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: border),
          CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(const Color(0xFF75715E)),
              textStyle: CodeBlockStyle.codeTextStyle().copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── VS Code Dark: realistic VS Code dark theme ────────────────────────────

  Widget _buildVscodeTemplate(BuildContext context, {required double radius}) {
    const bg = Color(0xFF1E1E1E);
    const header = Color(0xFF2D2D2D);
    const border = Color(0xFF404040);
    const accent = Color(0xFF569CD6);
    const tabActive = Color(0xFF1E1E1E);
    const textColor = Color(0xFFD4D4D4);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Activity bar row (VS Code-style tab)
          Container(
            color: header,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tabActive,
                    border: Border(top: BorderSide(color: accent, width: 1.5)),
                  ),
                  child: Text(
                    getLanguageDisplayName(
                      widget.block.style.language ?? 'text',
                    ),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.copy_outlined,
                    color: textColor,
                    size: 16,
                  ),
                  tooltip: 'Copy code',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _copyToClipboard(context);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: border),
          CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: CodeField(
              controller: _codeController,
              enabled: false,
              readOnly: true,
              wrap: false,
              gutterStyle: CodeBlockStyle.gutterStyle(const Color(0xFF858585)),
              textStyle: CodeBlockStyle.codeTextStyle().copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
