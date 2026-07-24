import 'dart:io';

import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/box_block_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/custom_border_painter.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoxReaderBlock extends ConsumerWidget {
  static const BorderRadius _borderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  final Block block;
  final Directory? docDir;

  const BoxReaderBlock({super.key, required this.block, this.docDir});

  Map<String, dynamic> _parseContent() {
    try {
      if (block.content.isNotEmpty) {
        return JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (error, stackTrace) {
      logger.e(
        'Failed to parse box content',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return <String, dynamic>{
      'text': '',
      'backgroundImage': null,
      'overlayOpacity': 0.3,
      'backgroundFit': 'cover',
    };
  }

  Widget? _buildBackground(
    Map<String, dynamic> content,
    double overlayOpacity,
  ) {
    final imageName = content['backgroundImage'] as String?;
    if (imageName == null || imageName.isEmpty || docDir == null) {
      return null;
    }

    final file = File('${docDir!.path}/$imageName');
    if (!file.existsSync()) return null;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: resolveBoxFit(
              sanitizeBoxBackgroundFit(content['backgroundFit']),
            ),
            onError: (_, __) {},
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: overlayOpacity),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final content = _parseContent();

    final hasBackground =
        (content['backgroundImage'] as String?)?.isNotEmpty ?? false;
    final overlayOpacity = sanitizeBoxOverlayOpacity(
      content['overlayOpacity'] as num?,
    );
    final borderStyle = sanitizeBoxBorderStyle(block.style.borderStyle);
    final boxHeight = sanitizeBoxHeight(block.style.height);
    final textAlign = styleUtils.textAlignFromStyle(block.style);
    final alignment = textAlign == TextAlign.center
        ? Alignment.center
        : textAlign == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseStyle = styleUtils
        .applyStyle(block.style)
        .copyWith(
          fontSize: block.style.fontSize * textMultiplier,
          color: hasBackground
              ? Colors.white
              : styleUtils.parseHex(block.style.color) ??
                    theme.colorScheme.onSurface,
          fontStyle: FontStyle.italic,
          fontWeight: hasBackground ? FontWeight.w600 : FontWeight.w400,
          height: ResponsiveUtils.getLineHeight(context, baseHeight: 1.5),
          shadows: hasBackground
              ? const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ]
              : null,
        );

    final linkStyle = baseStyle.copyWith(
      color: hasBackground
          ? Colors.white.withValues(alpha: 0.95)
          : theme.colorScheme.primary,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w600,
    );

    final surface = ClipRRect(
      borderRadius: _borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasBackground
              ? Colors.transparent
              : styleUtils.parseHex(block.style.background) ??
                    theme.colorScheme.surfaceContainerLow,
          gradient: !hasBackground && block.style.background == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
                    theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.18,
                    ),
                  ],
                )
              : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: boxHeight),
          child: Stack(
            children: [
              if (hasBackground) _buildBackground(content, overlayOpacity)!,
              Padding(
                padding: const EdgeInsets.all(18),
                child: Align(
                  alignment: alignment,
                  child: Semantics(
                    label: 'Box text',
                    child: RichText(
                      textAlign: textAlign,
                      text: LinkUtils.parseTextWithLinks(
                        content['text']?.toString() ?? '',
                        baseStyle,
                        linkStyle,
                        hasBackground
                            ? Colors.white
                            : theme.colorScheme.primary.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final borderColor =
        styleUtils.parseHex(block.style.borderColor) ??
        theme.colorScheme.primary;
    final borderedSurface = borderStyle == 'normal'
        ? surface
        : CustomPaint(
            painter: CustomBorderPainter(
              color: borderColor,
              style: borderStyle,
              strokeWidth: block.style.borderWidth.clamp(1.0, 8.0),
            ),
            child: surface,
          );

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getBlockSpacing(context),
      ),
      child: borderedSurface,
    );
  }
}
