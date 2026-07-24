import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/stepper_templates.dart';

/// Read-only display of stepper block with step-by-step layout.
class StepperReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory? docDir;
  final bool allowInteraction;

  const StepperReaderBlock({
    required this.block,
    this.docDir,
    this.allowInteraction = true,
    super.key,
  });

  @override
  ConsumerState<StepperReaderBlock> createState() => _StepperReaderBlockState();
}

class _StepperReaderBlockState extends ConsumerState<StepperReaderBlock> {
  final Set<int> _completedSteps = {};
  late Map<String, dynamic> _content;

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  void _parseContent() {
    final converter = JsonStringConverter();
    try {
      _content = converter.convertFromJsonString(widget.block.content);

      // Restore completed steps stored in the block's own JSON content.
      final savedCompleted =
          (_content['_completedSteps'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toSet() ??
          {};
      if (savedCompleted.isNotEmpty) {
        _completedSteps.addAll(savedCompleted);
      }
    } catch (e) {
      _content = {
        'steps': [],
        'orientation': 'vertical',
        'stepperTemplate': kDefaultStepperTemplate,
      };
    }
  }

  void _persistState() {
    if (widget.docDir == null) return;
    try {
      final updatedContent = Map<String, dynamic>.from(_content);
      updatedContent['_completedSteps'] = _completedSteps
          .map((e) => e.toString())
          .toList();
      final jsonString = JsonStringConverter().convertToJsonString(
        updatedContent,
      );
      final updatedBlock = widget.block.copyWith(content: jsonString);
      ref
          .read(editDocumentControllerProvider(widget.docDir!).notifier)
          .saveBlock(updatedBlock);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to persist stepper state',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _toggleStepCompletion(int index) {
    setState(() {
      if (_completedSteps.contains(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps.add(index);
      }
    });
    _persistState();
  }

  @override
  Widget build(BuildContext context) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final steps = _content['steps'] as List? ?? [];
    final orientation = _content['orientation']?.toString() ?? 'vertical';
    final stepperTemplate =
        _content['stepperTemplate']?.toString() ?? kDefaultStepperTemplate;

    // Apply block styles
    final fontSize = widget.block.style.fontSize;
    final parsedColor = styleUtils.parseHex(widget.block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final parsedBackground = styleUtils.parseHex(widget.block.style.background);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseTextStyle = styleUtils
        .applyStyle(widget.block.style)
        .copyWith(fontSize: fontSize * textMultiplier, color: color);

    if (steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          'No steps available',
          style: baseTextStyle.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return DefaultTextStyle(
      style: baseTextStyle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            _buildProgressHeader(theme, baseTextStyle, steps),
            _buildStepperWithTemplate(
              context,
              theme,
              steps,
              color,
              orientation,
              stepperTemplate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(
    ThemeData theme,
    TextStyle baseTextStyle,
    List steps,
  ) {
    final total = steps.length;
    final completed = steps
        .asMap()
        .entries
        .where(
          (e) =>
              (e.value as Map<String, dynamic>)['isCompleted'] == true ||
              _completedSteps.contains(e.key),
        )
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$completed of $total ${total == 1 ? 'step' : 'steps'} completed',
            style: baseTextStyle.copyWith(
              fontSize: (baseTextStyle.fontSize ?? 14) * 0.85,
              color: theme.colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0,
                minHeight: 4,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperWithTemplate(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
    String template,
  ) {
    // All templates fall back to _buildHorizontalStepper when orientation is horizontal
    if (orientation == 'horizontal') {
      return _buildHorizontalStepper(context, theme, steps, color);
    }

    // Render different templates based on the selected template
    switch (template) {
      case kStepperTemplateNumbered:
        return _buildNumberedStepper(context, theme, steps, color, orientation);
      case kStepperTemplateProgress:
        return _buildProgressStepper(context, theme, steps, color, orientation);
      case kStepperTemplateTimeline:
        return _buildTimelineStepper(context, theme, steps, color, orientation);
      case kStepperTemplateMinimal:
        return _buildMinimalStepper(context, theme, steps, color, orientation);
      case kStepperTemplateCards:
        return _buildCardsStepper(context, theme, steps, color, orientation);
      case kStepperTemplateChecklist:
        return _buildChecklistStepper(
          context,
          theme,
          steps,
          color,
          orientation,
        );
      case kStepperTemplateDots:
        return _buildDotsStepper(context, theme, steps, color, orientation);
      case kStepperTemplateStandard:
      default:
        return _buildVerticalStepper(context, theme, steps, color);
    }
  }

  Widget _buildVerticalStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isLast = index == steps.length - 1;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);

        return Column(
          children: [
            _buildStepItem(theme, step, index, color),
            if (!isLast)
              Container(
                margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                            isCompleted &&
                                    (steps[index + 1]['isCompleted'] ??
                                        _completedSteps.contains(index + 1))
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildHorizontalStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final step = steps[index] as Map<String, dynamic>;
          final isLast = index == steps.length - 1;
          final isCompleted =
              step['isCompleted'] ?? _completedSteps.contains(index);

          return Row(
            children: [
              SizedBox(
                width: 220,
                child: _buildStepItem(theme, step, index, color),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepItem(
    ThemeData theme,
    Map<String, dynamic> step,
    int index,
    Color color,
  ) {
    final isCompleted = step['isCompleted'] ?? _completedSteps.contains(index);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('check'),
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      )
                    : Text(
                        '${index + 1}',
                        key: ValueKey('number_$index'),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] ?? 'Step ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? color.withOpacity(0.6) : color,
                  ),
                ),
                if (step['description'] != null &&
                    step['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  MarkdownBody(
                    data: step['description'].toString(),
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isCompleted ? color.withOpacity(0.5) : color,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      em: TextStyle(fontStyle: FontStyle.italic, color: color),
                      code: TextStyle(fontFamily: 'monospace', color: color),
                    ),
                    onTapLink: (text, href, title) async {
                      if (href != null) await LinkUtils.launchURL(href);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Only make it interactive if allowInteraction is true
    if (widget.allowInteraction) {
      final title = step['title']?.toString() ?? 'Step ${index + 1}';
      return Semantics(
        label: '$title, ${isCompleted ? 'completed' : 'not completed'}',
        hint: 'Double tap to toggle completion',
        button: true,
        checked: isCompleted,
        child: GestureDetector(
          onTap: () => _toggleStepCompletion(index),
          child: child,
        ),
      );
    }

    return child;
  }

  // Template-specific stepper builders

  Widget _buildNumberedStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primaryContainer,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 22,
                        )
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] ?? 'Step ${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (step['description'] != null &&
                        step['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      MarkdownBody(
                        data: step['description'].toString(),
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: color.withOpacity(isCompleted ? 0.5 : 0.8),
                          ),
                          strong: TextStyle(fontWeight: FontWeight.bold),
                          em: TextStyle(fontStyle: FontStyle.italic),
                          code: TextStyle(fontFamily: 'monospace'),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href != null) await LinkUtils.launchURL(href);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProgressStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    final completedCount = steps.where((s) {
      final step = s as Map<String, dynamic>?;
      return step?['isCompleted'] ?? false;
    }).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(steps.length, (index) {
          final step = steps[index] as Map<String, dynamic>;
          final isCompleted =
              step['isCompleted'] ?? _completedSteps.contains(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: isCompleted
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step['title'] ?? 'Step ${index + 1}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);
        final isFirst = index == 0;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  if (!isFirst)
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.5),
                            theme.colorScheme.primary,
                          ],
                        ),
                      ),
                    ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 3,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: isCompleted
                      ? Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'] ?? 'Step ${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (step['description'] != null &&
                        step['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: step['description'].toString(),
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: color.withOpacity(isCompleted ? 0.5 : 0.8),
                          ),
                          strong: TextStyle(fontWeight: FontWeight.bold),
                          em: TextStyle(fontStyle: FontStyle.italic),
                          code: TextStyle(fontFamily: 'monospace'),
                        ),
                        onTapLink: (text, href, title) async {
                          if (href != null) await LinkUtils.launchURL(href);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMinimalStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step['title'] ?? 'Step ${index + 1}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? color.withOpacity(0.5) : color,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCardsStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceVariant,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted ? Icons.check : Icons.radio_button_unchecked,
                      color: isCompleted
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] ?? 'Step ${index + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (step['description'] != null &&
                          step['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        MarkdownBody(
                          data: step['description'].toString(),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: color.withOpacity(isCompleted ? 0.5 : 0.7),
                            ),
                            strong: TextStyle(fontWeight: FontWeight.bold),
                            em: TextStyle(fontStyle: FontStyle.italic),
                            code: TextStyle(fontFamily: 'monospace'),
                          ),
                          onTapLink: (text, href, title) async {
                            if (href != null) await LinkUtils.launchURL(href);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChecklistStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index] as Map<String, dynamic>;
        final isCompleted =
            step['isCompleted'] ?? _completedSteps.contains(index);

        final child = Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step['title'] ?? 'Step ${index + 1}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? color.withOpacity(0.5) : color,
                  ),
                ),
              ),
            ],
          ),
        );

        // Only make it interactive if allowInteraction is true
        if (widget.allowInteraction) {
          return InkWell(
            onTap: () => _toggleStepCompletion(index),
            child: child,
          );
        }

        return child;
      }),
    );
  }

  Widget _buildDotsStepper(
    BuildContext context,
    ThemeData theme,
    List steps,
    Color color,
    String orientation,
  ) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(steps.length, (index) {
              final step = steps[index] as Map<String, dynamic>;
              final isCompleted =
                  step['isCompleted'] ?? _completedSteps.contains(index);
              final prevStepCompleted = index > 0
                  ? ((steps[index - 1] as Map<String, dynamic>?)?.containsKey(
                              'isCompleted',
                            ) ==
                            true &&
                        (steps[index - 1]
                                as Map<String, dynamic>)['isCompleted'] ==
                            true)
                  : false;
              final isCurrent =
                  !isCompleted && (index == 0 || prevStepCompleted);

              return Container(
                width: isCurrent ? 32 : 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : isCurrent
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ),
        ...List.generate(steps.length, (index) {
          final step = steps[index] as Map<String, dynamic>;
          final isCompleted =
              step['isCompleted'] ?? _completedSteps.contains(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? theme.colorScheme.primary : color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step['title'] ?? 'Step ${index + 1}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? color.withOpacity(0.5) : color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
