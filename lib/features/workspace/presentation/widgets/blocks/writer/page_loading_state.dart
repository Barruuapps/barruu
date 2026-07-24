import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';

/// Builds a loading state widget for page block initialization.
///
/// Displays a shimmer indicator and message while a nested page is being created.
Widget buildPageBlockLoadingState(ThemeData theme) {
  return Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerInlineLoading(size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          'Creating page...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}
