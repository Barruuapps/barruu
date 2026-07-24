import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';

/// Empty state widget for displaying when there's no content
///
/// Provides a consistent, user-friendly UI for empty states with
/// actionable CTAs to help users get started.
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Description text
  final String description;

  /// Optional action button text
  final String? actionText;

  /// Optional action button callback
  final VoidCallback? onAction;

  /// Optional secondary action text
  final String? secondaryActionText;

  /// Optional secondary action callback
  final VoidCallback? onSecondaryAction;

  /// Optional custom illustration widget
  final Widget? illustration;

  /// Whether to show in compact mode (smaller)
  final bool compact;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.illustration,
    this.compact = false,
  });

  /// Factory for "No Documents" empty state
  factory EmptyStateWidget.noDocuments({
    VoidCallback? onCreateDocument,
    VoidCallback? onImportDocument,
  }) {
    return EmptyStateWidget(
      icon: Icons.description_outlined,
      title: 'No Documents Yet',
      description:
          'Create your first document or import an existing .bipy file to get started.',
      actionText: 'Create Document',
      onAction: onCreateDocument,
      secondaryActionText: 'Import .bipy File',
      onSecondaryAction: onImportDocument,
    );
  }

  /// Factory for "No Blocks" empty state
  factory EmptyStateWidget.noBlocks({VoidCallback? onAddBlock}) {
    return EmptyStateWidget(
      icon: Icons.add_box_outlined,
      title: 'Add a block',
      description: 'Tap the + button to add your first content block.',
      actionText: 'Add Block',
      onAction: onAddBlock,
      compact: true,
    );
  }

  /// Factory for "No Search Results" empty state
  factory EmptyStateWidget.noSearchResults({VoidCallback? onClearSearch}) {
    return EmptyStateWidget(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      description: 'Try adjusting your search terms or filters.',
      actionText: 'Clear Search',
      onAction: onClearSearch,
      compact: true,
    );
  }

  /// Factory for "Error" empty state
  factory EmptyStateWidget.error({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Something Went Wrong',
      description:
          message ?? 'We couldn\'t load the content. Please try again.',
      actionText: 'Retry',
      onAction: onRetry,
      compact: true,
    );
  }

  /// Factory for "Network Error" empty state
  factory EmptyStateWidget.networkError({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_outlined,
      title: 'No Internet Connection',
      description: 'Please check your connection and try again.',
      actionText: 'Retry',
      onAction: onRetry,
      compact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact ? 64.0 : 96.0;
    final spacing = compact ? 12.0 : 24.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 24.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or Icon
            if (illustration != null)
              illustration!
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: theme.colorScheme.primary,
                ),
              ),

            SizedBox(height: spacing),

            // Title
            Text(
              title,
              style:
                  (compact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: spacing / 2),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                description,
                style:
                    (compact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          height: 1.5,
                        ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: spacing * 1.5),

            // Action buttons
            if (onAction != null || onSecondaryAction != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary action
                    if (onAction != null && actionText != null)
                      ElevatedButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(actionText!),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 24 : 32,
                            vertical: compact ? 12 : 16,
                          ),
                        ),
                      ),

                    // Secondary action
                    if (onSecondaryAction != null &&
                        secondaryActionText != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onSecondaryAction,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: Text(secondaryActionText!),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 24 : 32,
                            vertical: compact ? 12 : 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with shimmer effect
class LoadingStateWidget extends StatelessWidget {
  /// Message to display while loading
  final String? message;

  /// Whether to show in compact mode
  final bool compact;

  const LoadingStateWidget({super.key, this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 48 : 64,
              height: compact ? 48 : 64,
              child: ShimmerCircularProgress(
                size: compact ? 48 : 64,
                color: theme.colorScheme.primary,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: compact ? 16 : 24),
              Text(
                message!,
                style:
                    (compact
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyLarge)
                        ?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
