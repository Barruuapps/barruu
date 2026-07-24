import 'dart:io';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:barruu/core/utils/app_logger.dart';

/// A card widget that displays a document's summary information.
/// 
/// This widget shows:
/// - Document cover image
/// - Document title and description
/// - Last modified date
/// - Popup menu for actions
/// 
/// The card is responsive and adapts its layout based on screen size.
class WorkspaceDocumentCard extends StatelessWidget {
  /// The directory containing the document
  final Directory doc;
  
  /// Cached metadata for the document
  final Map<String, dynamic> meta;
  
  /// Widget to display the cover image
  final Widget Function(String?, ThemeData) buildCoverImage;
  
  /// Widget for the popup menu button
  final Widget Function(Directory) buildPopupMenuButton;
  
  /// Callback when the card needs to show a snackbar
  final void Function(String message) onShowSnackBar;
  
  /// Callback when documents need to be reloaded
  final VoidCallback onReloadDocuments;

  const WorkspaceDocumentCard({
    super.key,
    required this.doc,
    required this.meta,
    required this.buildCoverImage,
    required this.buildPopupMenuButton,
    required this.onShowSnackBar,
    required this.onReloadDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = meta[MetaFile.nameKey]?.toString().trim() ?? 'Untitled Document';
    final description = meta[MetaFile.descriptionKey]?.toString().trim() ?? '';
    final lastModified = meta['lastModified'] as DateTime? ?? DateTime.now();
    final coverImageUrl = meta[MetaFile.coverKey]?.toString();
    final formattedDate = DateFormat('MMM d, yyyy').format(lastModified);

    final borderRadius = ResponsiveUtils.getBorderRadius(context, baseRadius: 20.0);
    final elevation = ResponsiveUtils.getElevation(context, baseElevation: 8.0);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final cardMinWidth = ResponsiveUtils.getCardMinWidth(context);

    return Container(
      constraints: BoxConstraints(minWidth: cardMinWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        color: theme.colorScheme.surfaceContainer,
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          onTap: () => _handleCardTap(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: buildCoverImage(coverImageUrl, theme),
                      ),
                    ),
                    // Gradient overlay for better text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.colorScheme.surface.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: buildPopupMenuButton(doc),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.isDesktop(context) ? 20.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: theme.colorScheme.onSurface,
                            height: 1.3,
                            fontSize: theme.textTheme.titleMedium?.fontSize != null
                                ? theme.textTheme.titleMedium!.fontSize! * textMultiplier
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.isDesktop(context) ? 6 : 4),
                        Flexible(
                          child: Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                              fontSize: theme.textTheme.bodySmall?.fontSize != null
                                  ? theme.textTheme.bodySmall!.fontSize! * textMultiplier
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.isDesktop(context) ? 12 : 10,
                          vertical: ResponsiveUtils.isDesktop(context) ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, baseRadius: 8.0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconsaxPlusLinear.calendar,
                              size: ResponsiveUtils.getIconSize(context, baseSize: 13.0),
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 11 * textMultiplier,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles tap on the document card, navigating to the document
  Future<void> _handleCardTap(BuildContext context) async {
    try {
      final docPath = Uri.encodeComponent(doc.path);
      await context.push('/preview-document/$docPath');
      onReloadDocuments();
    } catch (e, stackTrace) {
      logger.e('Navigation error: ${doc.path}', error: e, stackTrace: stackTrace);
      onShowSnackBar('Failed to open document');
    }
  }
}
