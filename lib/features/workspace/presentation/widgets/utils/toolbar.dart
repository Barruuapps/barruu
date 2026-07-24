import 'dart:io';

import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/provider/constants_providers.dart';
import 'package:barruu/features/workspace/presentation/widgets/color_picker.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/header_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/checkbox_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/list_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/table_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/page_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/expandable_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/multiple_choice_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/true_false_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/fill_blank_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/matching_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/reorder_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/stem_controls.dart';
import 'package:barruu/features/workspace/presentation/widgets/controllers/code_controls.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Toolbar widget for editing block styles
class Toolbar extends ConsumerWidget {
  final Block block;
  final Directory docDir;
  final Widget? child;

  const Toolbar({
    super.key,
    required this.block,
    required this.docDir,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final styleUtils = ref.read(styleUtilsProvider);
      final controller = ref.read(
        editDocumentControllerProvider(docDir).notifier,
      );
      final fontFamilies = ref.watch(fontFamiliesProvider);
      final fontSizes = ref.watch(fontSizesProvider);
      final supportedLanguages = ref.watch(supportedLanguagesProvider);
      final theme = Theme.of(context);

      return Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = ResponsiveUtils.useCompactLayout(context);
              final isMobile = ResponsiveUtils.isMobile(context);
              // Increased base size from 20 to 24 for better mobile visibility
              final iconSize = ResponsiveUtils.getIconSize(context);
              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: isCompact ? 8 : 10,
                  horizontal: isCompact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TextStyleControls(
                        controller: controller,
                        block: block,
                        styleUtils: styleUtils,
                        isCompact: isCompact,
                      ),
                      _buildDivider(theme, isCompact),
                      ColorPickerControls(
                        controller: controller,
                        block: block,
                        styleUtils: styleUtils,
                      ),
                      _buildDivider(theme, isCompact),
                      _AlignmentControls(
                        controller: controller,
                        block: block,
                        isCompact: isCompact,
                      ),
                      _buildDivider(theme, isCompact),
                      _FontControls(
                        controller: controller,
                        block: block,
                        fontFamilies: fontFamilies,
                        fontSizes: fontSizes,
                      ),
                      if (block.type == BlockType.header ||
                          block.type == BlockType.list ||
                          block.type == BlockType.code ||
                          block.type == BlockType.table ||
                          block.type == BlockType.checkbox ||
                          block.type == BlockType.page ||
                          block.type == BlockType.expandable ||
                          block.type == BlockType.paragraph ||
                          block.type == BlockType.multipleChoice ||
                          block.type == BlockType.trueFalse ||
                          block.type == BlockType.fillInBlank ||
                          block.type == BlockType.matching ||
                          block.type == BlockType.wordOrder ||
                          block.type == BlockType.mathWorkpad ||
                          block.type == BlockType.theorem ||
                          block.type == BlockType.proof ||
                          block.type == BlockType.definition ||
                          block.type == BlockType.example ||
                          block.type == BlockType.learningObjective ||
                          block.type == BlockType.conceptSummary ||
                          block.type == BlockType.numericalQuestion ||
                          block.type == BlockType.glossary ||
                          block.type == BlockType.parametricGraph ||
                          block.type == BlockType.citation ||
                          block.type == BlockType.toc ||
                          block.type == BlockType.faq ||
                          block.type == BlockType.keyPoint ||
                          (block.type == BlockType.math && child != null) ||
                          (block.type == BlockType.graph && child != null))
                        _buildDivider(theme, isCompact),
                      if (block.type == BlockType.header)
                        HeaderControls(controller: controller, block: block),
                      if (block.type == BlockType.checkbox)
                        CheckboxControls(controller: controller, block: block),
                      if (block.type == BlockType.list)
                        ListControls(controller: controller, block: block),
                      if (block.type == BlockType.table)
                        TableControls(controller: controller, block: block),
                      if (block.type == BlockType.page)
                        PageControls(controller: controller, block: block),
                      if (block.type == BlockType.expandable)
                        ExpandableControls(
                          controller: controller,
                          block: block,
                        ),
                      if (block.type == BlockType.multipleChoice)
                        MultipleChoiceControls(
                          controller: controller,
                          block: block,
                        ),
                      if (block.type == BlockType.trueFalse)
                        TrueFalseControls(controller: controller, block: block),
                      if (block.type == BlockType.fillInBlank)
                        FillBlankControls(controller: controller, block: block),
                      if (block.type == BlockType.matching)
                        MatchingControls(controller: controller, block: block),
                      if (block.type == BlockType.wordOrder ||
                          block.type == BlockType.mathWorkpad)
                        ReorderControls(controller: controller, block: block),
                      if (block.type == BlockType.theorem ||
                          block.type == BlockType.proof ||
                          block.type == BlockType.definition ||
                          block.type == BlockType.example ||
                          block.type == BlockType.learningObjective ||
                          block.type == BlockType.conceptSummary ||
                          block.type == BlockType.numericalQuestion ||
                          block.type == BlockType.glossary ||
                          block.type == BlockType.parametricGraph ||
                          block.type == BlockType.citation ||
                          block.type == BlockType.toc ||
                          block.type == BlockType.faq ||
                          block.type == BlockType.keyPoint)
                        StemControls(controller: controller, block: block),
                      if (block.type == BlockType.paragraph && child != null)
                        child!,
                      if (block.type == BlockType.code)
                        _CodeControls(
                          controller: controller,
                          block: block,
                          supportedLanguages: supportedLanguages,
                        ),
                      if (block.type == BlockType.code)
                        CodeControls(controller: controller, block: block),
                      if (block.type == BlockType.math && child != null ||
                          block.type == BlockType.graph && child != null)
                        child!,
                      _buildDivider(theme, isCompact),
                      // reset recent styles for the current block
                      Tooltip(
                        message: 'Reset Styles',
                        waitDuration: const Duration(milliseconds: 500),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => controller.resetRecentStyles(block),
                            child: Container(
                              padding: EdgeInsets.all(
                                isMobile ? 10 : (isCompact ? 6 : 8),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Icon(
                                isMobile
                                    ? IconsaxPlusBold.refresh
                                    : IconsaxPlusLinear.refresh,
                                color: theme.colorScheme.primary,
                                size: isMobile ? 22 : (isCompact ? 18 : 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to build Toolbar for block ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return const Center(
        child: Text(
          'Error loading toolbar',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildDivider(ThemeData theme, bool isCompact) {
    return Container(
      width: 1,
      height: isCompact ? 24 : 28,
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Controls for text style toggles (bold, italic, etc.)
class _TextStyleControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final StyleUtils styleUtils;
  final bool isCompact;

  const _TextStyleControls({
    required this.controller,
    required this.block,
    required this.styleUtils,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = block.style;
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          icon: isMobile
              ? IconsaxPlusBold.text_bold
              : IconsaxPlusLinear.text_bold,
          isActive: style.bold,
          tooltip: 'Bold',
          semanticsLabel: 'Toggle bold',
          onPressed: () => _updateStyle(
            context,
            controller,
            block,
            style.copyWith(bold: !style.bold),
          ),
          ref: ref,
          context: context,
          isCompact: isCompact,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        _buildIconButton(
          icon: isMobile
              ? IconsaxPlusBold.text_italic
              : IconsaxPlusLinear.text_italic,
          isActive: style.italic,
          tooltip: 'Italic',
          semanticsLabel: 'Toggle italic',
          onPressed: () => _updateStyle(
            context,
            controller,
            block,
            style.copyWith(italic: !style.italic),
          ),
          ref: ref,
          context: context,
          isCompact: isCompact,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        _buildIconButton(
          icon: isMobile
              ? IconsaxPlusBold.text_underline
              : IconsaxPlusLinear.text_underline,
          isActive: style.underline,
          tooltip: 'Underline',
          semanticsLabel: 'Toggle underline',
          onPressed: () => _updateStyle(
            context,
            controller,
            block,
            style.copyWith(underline: !style.underline),
          ),
          ref: ref,
          context: context,
          isCompact: isCompact,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        _buildIconButton(
          icon: Icons
              .format_strikethrough, // Using Material Icons for semantic clarity
          isActive: style.strikethrough,
          tooltip: 'Strikethrough',
          semanticsLabel: 'Toggle strikethrough',
          onPressed: () => _updateStyle(
            context,
            controller,
            block,
            style.copyWith(strikethrough: !style.strikethrough),
          ),
          ref: ref,
          context: context,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Future<void> _updateStyle(
    BuildContext context,
    EditDocumentController controller,
    Block block,
    BlockStyle style,
  ) async {
    try {
      await controller.updateStyle(block, style);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update style for block ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update style: $e')));
      }
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required String semanticsLabel,
    required VoidCallback onPressed,
    required WidgetRef ref,
    required BuildContext context,
    bool isCompact = false,
  }) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    // Increased padding for better touch targets on mobile
    final buttonPadding = isMobile ? 10.0 : (isCompact ? 6.0 : 8.0);
    // Increased icon size for better visibility
    final buttonIconSize = isMobile ? 22.0 : (isCompact ? 18.0 : 20.0);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(buttonPadding),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: buttonIconSize,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              semanticLabel: semanticsLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Controls for text alignment
class _AlignmentControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final bool isCompact;

  const _AlignmentControls({
    required this.controller,
    required this.block,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = block.style;
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    // Mixed icon approach: IconsaxPlus for left/right/center, Material Icons for justify
    // since iconsax_plus doesn't have a dedicated justify/distributed alignment icon
    final icon =
        {
          'center': isMobile
              ? IconsaxPlusBold.align_horizontally
              : IconsaxPlusLinear.align_horizontally,
          'right': isMobile
              ? IconsaxPlusBold.align_right
              : IconsaxPlusLinear.align_right,
          'justify': Icons
              .format_align_justify, // Material Icons - no equivalent in iconsax_plus
          'left': isMobile
              ? IconsaxPlusBold.align_left
              : IconsaxPlusLinear.align_left,
        }[style.align] ??
        (isMobile ? IconsaxPlusBold.align_left : IconsaxPlusLinear.align_left);

    final buttonPadding = isMobile ? 10.0 : (isCompact ? 6.0 : 8.0);
    final buttonIconSize = isMobile ? 22.0 : (isCompact ? 18.0 : 20.0);

    return Tooltip(
      message: 'Text Alignment',
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            try {
              final next = _nextAlign(style.align);
              await controller.updateStyle(block, style.copyWith(align: next));
            } catch (e, stackTrace) {
              logger.e(
                'Failed to update alignment for block ${block.id}',
                error: e,
                stackTrace: stackTrace,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update alignment: $e')),
                );
              }
            }
          },
          child: Container(
            padding: EdgeInsets.all(buttonPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: buttonIconSize,
              semanticLabel: 'Toggle alignment',
            ),
          ),
        ),
      ),
    );
  }

  String _nextAlign(String? current) {
    const alignments = ['left', 'center', 'justify', 'right'];
    final currentIndex = alignments.indexOf(current ?? 'left');
    return alignments[(currentIndex + 1) % alignments.length];
  }
}

/// Controls for font size and family
class _FontControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final List<String> fontFamilies;
  final List<double> fontSizes;

  const _FontControls({
    required this.controller,
    required this.block,
    required this.fontFamilies,
    required this.fontSizes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = block.style;
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Font Size',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<double>(
              itemBuilder: (_) => fontSizes
                  .map(
                    (size) => PopupMenuItem(
                      value: size,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          size.toInt().toString(),
                          style: TextStyle(
                            fontWeight: size == style.fontSize
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: size == style.fontSize
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (value) async {
                try {
                  await controller.updateStyle(
                    block,
                    style.copyWith(fontSize: value),
                  );
                } catch (e, stackTrace) {
                  logger.e(
                    'Failed to update font size for block ${block.id}',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update font size: $e')),
                    );
                  }
                }
              },
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMobile ? IconsaxPlusBold.text : IconsaxPlusLinear.text,
                      color: theme.colorScheme.primary,
                      size: isMobile ? 22 : 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      style.fontSize.toInt().toString() ?? '14',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isMobile
                          ? IconsaxPlusBold.arrow_down
                          : IconsaxPlusLinear.arrow_down_1,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Font Family',
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            child: PopupMenuButton<String>(
              itemBuilder: (_) => fontFamilies
                  .map(
                    (font) => PopupMenuItem(
                      value: font,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          font,
                          style: TextStyle(
                            fontWeight: font == style.fontFamily
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: font == style.fontFamily
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (value) async {
                try {
                  await controller.updateStyle(
                    block,
                    style.copyWith(fontFamily: value),
                  );
                } catch (e, stackTrace) {
                  logger.e(
                    'Failed to update font family for block ${block.id}',
                    error: e,
                    stackTrace: stackTrace,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update font family: $e'),
                      ),
                    );
                  }
                }
              },
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMobile
                          ? IconsaxPlusBold.text_block
                          : IconsaxPlusLinear.text_block,
                      color: theme.colorScheme.primary,
                      size: isMobile ? 22 : 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (style.fontFamily ?? 'Default').length > 8
                          ? '${(style.fontFamily ?? 'Default').substring(0, 8)}...'
                          : (style.fontFamily ?? 'Default'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      isMobile
                          ? IconsaxPlusBold.arrow_down
                          : IconsaxPlusLinear.arrow_down_1,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Controls for code block language selection
class _CodeControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final List<String> supportedLanguages;

  const _CodeControls({
    required this.controller,
    required this.block,
    required this.supportedLanguages,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    return PopupMenuButton<String>(
      icon: Icon(
        isMobile ? IconsaxPlusBold.code_1 : IconsaxPlusLinear.code_1,
        color: theme.colorScheme.primary,
        size: isMobile ? 22 : 20,
        semanticLabel: 'Select code language',
      ),
      tooltip: 'Language',
      itemBuilder: (_) => supportedLanguages
          .map(
            (lang) => PopupMenuItem(
              value: lang,
              child: Text(
                getLanguageDisplayName(lang),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          )
          .toList(),
      onSelected: (lang) async {
        try {
          await controller.updateStyle(
            block,
            block.style.copyWith(language: lang),
          );
        } catch (e, stackTrace) {
          logger.e(
            'Failed to update code language for block ${block.id}',
            error: e,
            stackTrace: stackTrace,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update code language: $e')),
            );
          }
        }
      },
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
