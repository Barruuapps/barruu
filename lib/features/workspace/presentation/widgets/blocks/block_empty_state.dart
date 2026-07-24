import 'package:flutter/material.dart';

/// A friendly empty-state placeholder used by container blocks (Cards, Rows,
/// Tabs, Table, Stepper, Columns) when they have no items yet.
///
/// Usage:
/// ```dart
/// if (items.isEmpty)
///   BlockEmptyState(
///     icon: Icons.view_column_outlined,
///     message: 'No columns yet',
///     actionLabel: 'Add Column',
///     onAction: _addColumn,
///   ),
/// ```
class BlockEmptyState extends StatelessWidget {
  const BlockEmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;

  /// Optional label for the primary call-to-action button.
  final String? actionLabel;

  /// Callback invoked when the action button is tapped.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
