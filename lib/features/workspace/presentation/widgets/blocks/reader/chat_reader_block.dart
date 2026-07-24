
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Reader widget for displaying chat content
class ChatReaderBlock extends ConsumerWidget {
  final Block block;

  const ChatReaderBlock({
    super.key,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final styleUtils = ref.read(styleUtilsProvider);
    final isRight = block.style.align == 'right';
    final backgroundColor = styleUtils.parseHex(block.style.background) ??
        (isRight ? theme.colorScheme.primary.withValues(alpha: 0.15) : theme.colorScheme.secondaryContainer.withValues(alpha: 0.8));
    final textColor = styleUtils.parseHex(block.style.color) ?? 
        (isRight ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer);

    final isWide = MediaQuery.of(context).size.width > 600;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final padding = EdgeInsets.symmetric(
      horizontal: isDesktop ? 20 : 16, 
      vertical: isDesktop ? 14 : 12,
    );
    final margin = EdgeInsets.symmetric(
      horizontal: isDesktop ? 12 : 8, 
      vertical: ResponsiveUtils.getBlockSpacing(context) / 2,
    );
    final maxWidth = isDesktop ? 600.0 : (isWide ? 500.0 : 340.0);

    Map<String, dynamic> content = {'message': '', 'profileName': ''};
    try {
      if (block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(block.content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse block content', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat content: $e')),
        );
      }
    }

    final message = content['message']?.toString() ?? '';
    final profileName = content['profileName']?.toString() ?? '';
    if (message.isEmpty) return const SizedBox.shrink();

    final baseStyle = styleUtils.applyStyle(block.style).copyWith(
      fontSize: block.style.fontSize,
      color: textColor,
      height: 1.4,
    );

    final linkStyle = baseStyle.copyWith(
      color: isRight 
          ? theme.colorScheme.primary.withValues(alpha: 0.9) 
          : theme.colorScheme.primary,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w500,
    );

    final hoverColor = theme.colorScheme.primary.withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.getBlockSpacing(context) / 2, 
        horizontal: 4,
      ),
      child: Row(
        mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRight)
            Padding(
              padding: EdgeInsets.only(
                right: isDesktop ? 10 : 8, 
                top: 4,
              ),
              child: CircleAvatar(
                radius: isDesktop ? 18 : 16,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: profileName.isNotEmpty
                    ? Text(
                        profileName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        size: isDesktop ? 18 : 16,
                        color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.6),
                      ),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Profile name if provided
                if (profileName.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: isRight ? 0 : 12,
                      right: isRight ? 12 : 0,
                      bottom: 4,
                    ),
                    child: Text(
                      profileName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                // Message bubble
                Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: padding,
                  margin: margin,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isRight ? 20 : 4),
                      topRight: Radius.circular(isRight ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    border: Border.all(
                      color: isRight 
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Semantics(
                    label: profileName.isNotEmpty ? '$profileName says: $message' : 'Chat message: $message',
                    child: RichText(
                      text: LinkUtils.parseTextWithLinks(
                        message,
                        baseStyle,
                        linkStyle,
                        hoverColor,
                      ),
                      textAlign: styleUtils.textAlignFromStyle(block.style),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isRight)
            Padding(
              padding: EdgeInsets.only(left: isDesktop ? 10 : 8, top: 4),
              child: CircleAvatar(
                radius: isDesktop ? 18 : 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: profileName.isNotEmpty
                    ? Text(
                        profileName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        size: isDesktop ? 18 : 16,
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
