import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// Premium empty state widget with generous spacing, beautiful iconography,
/// and clear calls-to-action. Matches the quality bar of Notion, Linear,
/// and other premium desktop apps.
///
/// ## Pre-built factories
/// - [PremiumEmptyState.noDocuments]
/// - [PremiumEmptyState.noFavorites]
/// - [PremiumEmptyState.noSearchResults]
/// - [PremiumEmptyState.noTemplates]
/// - [PremiumEmptyState.noFolderSelected]
/// - [PremiumEmptyState.noActivity]
/// - [PremiumEmptyState.error]
class PremiumEmptyState extends StatelessWidget {
  /// Large icon shown at the top
  final IconData icon;

  /// Primary title text
  final String title;

  /// Descriptive subtitle text
  final String subtitle;

  /// Primary action label
  final String? actionLabel;

  /// Primary action callback
  final VoidCallback? onAction;

  /// Secondary action label
  final String? secondaryActionLabel;

  /// Secondary action callback
  final VoidCallback? onSecondaryAction;

  /// Custom color for the icon circle background
  final Color? iconBackgroundColor;

  /// Custom color for the icon
  final Color? iconColor;

  /// Whether to use compact mode (for sidebars, small panels)
  final bool compact;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconBackgroundColor,
    this.iconColor,
    this.compact = false,
  });

  // ─── Factory constructors ────────────────────────────────────────────

  factory PremiumEmptyState.noDocuments({
    VoidCallback? onCreate,
    VoidCallback? onImport,
  }) {
    return PremiumEmptyState(
      icon: Icons.article_rounded,
      title: 'No documents yet',
      subtitle:
          'Create your first document or import an existing .bipy file to get started.',
      actionLabel: 'Create Document',
      onAction: onCreate,
      secondaryActionLabel: 'Import .bipy',
      onSecondaryAction: onImport,
    );
  }

  factory PremiumEmptyState.noFavorites({VoidCallback? onBrowse}) {
    return PremiumEmptyState(
      icon: Icons.star_rounded,
      title: 'No favorites',
      subtitle:
          'Documents you mark as favorites will appear here for quick access.',
      actionLabel: 'Browse Documents',
      onAction: onBrowse,
    );
  }

  factory PremiumEmptyState.noSearchResults({VoidCallback? onClear}) {
    return PremiumEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      subtitle: 'Try adjusting your search terms or browse by category.',
      actionLabel: 'Clear search',
      onAction: onClear,
      compact: true,
    );
  }

  factory PremiumEmptyState.noTemplates({VoidCallback? onCreateBlank}) {
    return PremiumEmptyState(
      icon: Icons.dashboard_customize_rounded,
      title: 'No templates',
      subtitle: 'Start from a blank canvas or import template packs.',
      actionLabel: 'Blank Document',
      onAction: onCreateBlank,
    );
  }

  factory PremiumEmptyState.noFolderSelected() {
    return PremiumEmptyState(
      icon: Icons.folder_open_rounded,
      title: 'Select a folder',
      subtitle: 'Choose a folder from the sidebar to view its documents.',
      compact: true,
    );
  }

  factory PremiumEmptyState.noActivity() {
    return PremiumEmptyState(
      icon: Icons.timeline_rounded,
      title: 'No recent activity',
      subtitle:
          'Your recent document activity will show up here once you start working.',
      compact: true,
    );
  }

  factory PremiumEmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return PremiumEmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      subtitle: message ?? 'We couldn\'t load the content. Please try again.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconBackgroundColor: Colors.red.shade50,
      iconColor: Colors.red.shade600,
    );
  }

  factory PremiumEmptyState.comingSoon({String? feature}) {
    return PremiumEmptyState(
      icon: Icons.construction_rounded,
      title: feature != null ? '$feature — Coming Soon' : 'Coming Soon',
      subtitle: 'This feature is under active development. Stay tuned!',
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact
        ? DesignTokens.icon2XLarge
        : DesignTokens.iconHero;
    final circleSize = compact ? 80.0 : 120.0;
    final spacing = compact
        ? DesignTokens.spacing16
        : DesignTokens.spacing24;
    final bgColor = iconBackgroundColor ??
        theme.colorScheme.primaryContainer.withValues(alpha: 0.25);
    final fgColor = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          compact ? DesignTokens.spacing24 : DesignTokens.spacing32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle — soft gradient feel through container
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: fgColor.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: fgColor,
              ),
            ),

            SizedBox(height: spacing),

            // Title
            Text(
              title,
              style: (compact
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: DesignTokens.lineHeightHeading,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: spacing * 0.5),

            // Subtitle — constrained width for readability
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                subtitle,
                style: (compact
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: DesignTokens.opacitySubtle),
                  height: DesignTokens.lineHeightBody,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Actions
            if (onAction != null || onSecondaryAction != null) ...[
              SizedBox(height: spacing * 1.5),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary action
                    if (onAction != null && actionLabel != null)
                      FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(
                          Icons.add_rounded,
                          size: DesignTokens.iconCompact,
                        ),
                        label: Text(actionLabel!),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                compact ? DesignTokens.spacing12 : DesignTokens.spacing16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusLarge,
                            ),
                          ),
                        ),
                      ),

                    // Secondary action
                    if (onSecondaryAction != null &&
                        secondaryActionLabel != null) ...[
                      SizedBox(height: DesignTokens.spacing12),
                      OutlinedButton.icon(
                        onPressed: onSecondaryAction,
                        icon: const Icon(
                          Icons.file_upload_outlined,
                          size: DesignTokens.iconCompact,
                        ),
                        label: Text(secondaryActionLabel!),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                compact ? DesignTokens.spacing12 : DesignTokens.spacing16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusLarge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}