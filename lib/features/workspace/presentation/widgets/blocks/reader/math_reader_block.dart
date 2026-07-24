
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathReaderBlock extends ConsumerWidget {
  final Block block;

  const MathReaderBlock({
    super.key,
    required this.block,
  });

  List<String> _parseEquations(String latex) {
    if (latex.isEmpty) return [];

    // Split by newlines and filter out empty lines
    return latex.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Widget _buildEmptyMath(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Empty math block',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.functions, size: 20, color: theme.colorScheme.outline),
            const SizedBox(width: 8),
            Text(
              'Empty math block',
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMath(BuildContext context, WidgetRef ref, String equation) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Math error',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
          color: theme.colorScheme.error.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Invalid LaTeX: ${equation.length > 50 ? '${equation.substring(0, 50)}...' : equation}',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMathEquation(
      String equation,
      TextStyle textStyle,
      Color color,
      Color background,
      TextAlign textAlign,
      WidgetRef ref,
      BuildContext context,
      ) {
    if (equation.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: background.withValues(alpha: 0.05),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              equation,
              textStyle: textStyle.copyWith(
                color: color,
                fontSize: (textStyle.fontSize ?? 16) * 1.2,
                fontWeight: FontWeight.w400,
              ),
              onErrorFallback: (FlutterMathException e) => _buildErrorMath(context, ref, equation),
            ),
          ),
        ),
      ),
    );
  }

  TextAlign _getTextAlignFromStyle(TextStyle style, BuildContext context) {
    // Extract alignment from style or use context-based default
    // This is a simplified version - you might need to adjust based on your StyleUtils
    return TextAlign.start;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);

    final background = styleUtils.parseHex(block.style.background) ?? theme.colorScheme.surface;
    final color = styleUtils.parseHex(block.style.color) ?? theme.colorScheme.onSurface;
    final textAlign = _getTextAlignFromStyle(styleUtils.applyStyle(block.style), context);

    Map<String, dynamic> content = {
      'latex': '',
      'caption': '',
    };

    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse JSON block content', error: e, stackTrace: stackTrace);
      return _buildErrorMath(context, ref, 'Content parsing error');
    }

    final latex = content['latex']?.toString() ?? '';
    final caption = content['caption']?.toString() ?? '';

    if (latex.isEmpty && caption.isEmpty) {
      return _buildEmptyMath(context, ref);
    }

    try {
      final equations = _parseEquations(latex);

      final isWide = MediaQuery.of(context).size.width > 600;
      final isDesktop = ResponsiveUtils.isDesktop(context);
      final horizontalPadding = isDesktop ? 24.0 : (isWide ? 16.0 : 12.0);
      final verticalPadding = isDesktop ? 16.0 : (isWide ? 12.0 : 8.0);
      final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
      final verticalMargin = ResponsiveUtils.getBlockSpacing(context);
      final margin = EdgeInsets.symmetric(vertical: verticalMargin);

      return Container(
        padding: padding,
        margin: margin,
        child: Column(
          crossAxisAlignment: _getCrossAxisAlignment(textAlign),
          children: [
            if (equations.isNotEmpty)
              ...equations.map((equation) => _buildMathEquation(
                equation,
                styleUtils.applyStyle(block.style),
                color,
                background,
                textAlign,
                ref,
                context,
              )),
            if (equations.isEmpty)
              _buildMathEquation(
                r'\text{[Empty math block]}',
                styleUtils.applyStyle(block.style),
                color,
                background,
                textAlign,
                ref,
                context,
              ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    caption,
                    style: styleUtils.applyStyle(block.style).copyWith(
                      fontSize: (styleUtils.applyStyle(block.style).fontSize ?? 14) * 0.9,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: textAlign,
                  ),
                ),
              ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      logger.e('Unexpected error in MathReaderBlock', error: e, stackTrace: stackTrace);
      return _buildErrorMath(context, ref, 'Rendering error: $e');
    }
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