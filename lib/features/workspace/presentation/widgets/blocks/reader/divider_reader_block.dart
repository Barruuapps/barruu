
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/divider_painter.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Enum for divider styles
enum DividerStyle { solid, dashed, dotted, double, threeDot }

// Reader widget for displaying divider content
class DividerReaderBlock extends ConsumerWidget {
  final Block block;

  const DividerReaderBlock({
    super.key,
    required this.block,
  });

  Widget _buildErrorDivider(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Divider error',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.error),
          borderRadius: BorderRadius.circular(4),
          color: theme.colorScheme.error.withValues(alpha: 0.1),
        ),
        child: Text(
          'Error displaying divider.',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);

    Map<String, dynamic> content = {
      'style': 'solid',
      'thickness': 2.0,
    };

    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse JSON block content', error: e, stackTrace: stackTrace);
      return _buildErrorDivider(context, ref);
    }

    // Parse divider style
    final DividerStyle dividerStyle;
    try {
      dividerStyle = DividerStyle.values.firstWhere(
            (e) => e.toString().split('.').last == content['style'],
        orElse: () => DividerStyle.solid,
      );
    } catch (e) {
      logger.e('Error parsing divider style, defaulting to solid: $e');
      return _buildErrorDivider(context, ref);
    }

    // Parse thickness with platform-aware adjustment
    final double thickness;
    try {
      final baseThickness = (content['thickness'] as num?)?.toDouble() ?? 2.0;
      // Apple HIG: Thinner dividers (0.5-1pt)
      // Android: Standard thickness (1-2dp)
      thickness = PlatformThemeHelper.isAndroid 
          ? baseThickness 
          : baseThickness * 0.75; // 25% thinner on Apple platforms
    } catch (e) {
      logger.e('Error parsing thickness, defaulting to 2.0: $e');
      return _buildErrorDivider(context, ref);
    }

    final backgroundColor = styleUtils.parseHex(block.style.background);
    final color = styleUtils.parseHex(block.style.color) ?? theme.colorScheme.primary;
    final align = block.style.align;

    final isWide = MediaQuery.of(context).size.width > 600;
    final padding = isWide 
        ? EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing16) 
        : EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing4);
    final margin = EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing8);
    
    return Container(
      padding: padding,
      margin: margin,
      color: backgroundColor,
      child: Align(
        alignment: dividerStyle == DividerStyle.threeDot
            ? Alignment.center
            : _getAlignment(align),
        child: dividerStyle == DividerStyle.threeDot
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing8),
            // Platform-specific dot size
            width: PlatformThemeHelper.isAndroid ? 8.0 : 6.0,
            height: PlatformThemeHelper.isAndroid ? 8.0 : 6.0,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )),
        )
            : CustomPaint(
          size: Size(double.infinity, thickness),
          painter: DividerPainter(
            style: dividerStyle,
            // Platform-specific opacity (Apple: more subtle)
            color: color.withValues(alpha: PlatformThemeHelper.isAndroid ? 0.6 : 0.4),
            thickness: thickness,
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(String? align) {
    switch (align) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}