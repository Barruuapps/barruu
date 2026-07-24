import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';

/// Centralized UI utility functions for consistent user feedback across the app.
///
/// This class provides reusable methods for common UI operations like showing
/// snackbars, dialogs, and other feedback mechanisms, ensuring consistency
/// and reducing code duplication throughout the application.
class UIUtils {
  // Private constructor to prevent instantiation
  UIUtils._();

  /// Shows a snackbar with the given message.
  ///
  /// [context] - The BuildContext to show the snackbar in
  /// [message] - The message to display
  /// [isError] - Whether this is an error message (changes color)
  /// [duration] - How long to show the snackbar (default: 2 seconds)
  ///
  /// Example:
  /// ```dart
  /// UIUtils.showSnackBar(context, 'Document saved successfully');
  /// UIUtils.showSnackBar(context, 'Failed to save', isError: true);
  /// ```
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: isError
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Shows a loading dialog with a circular progress indicator.
  ///
  /// [context] - The BuildContext to show the dialog in
  /// [message] - The loading message to display
  /// [barrierDismissible] - Whether the dialog can be dismissed by tapping outside
  ///
  /// Returns the dialog's Future which can be used to dismiss it later.
  ///
  /// Example:
  /// ```dart
  /// UIUtils.showLoadingDialog(context, 'Saving document...');
  /// // Do work
  /// Navigator.of(context).pop(); // Dismiss when done
  /// ```
  static Future<void> showLoadingDialog(
    BuildContext context,
    String message, {
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerCircularProgress(
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog with customizable title, message, and actions.
  ///
  /// [context] - The BuildContext to show the dialog in
  /// [title] - The dialog title
  /// [message] - The dialog message/content
  /// [confirmText] - Text for the confirm button (default: 'Confirm')
  /// [cancelText] - Text for the cancel button (default: 'Cancel')
  /// [isDestructive] - Whether the confirm action is destructive (changes color to red)
  ///
  /// Returns true if confirmed, false if cancelled.
  ///
  /// Example:
  /// ```dart
  /// final confirmed = await UIUtils.showConfirmDialog(
  ///   context,
  ///   title: 'Delete Document',
  ///   message: 'Are you sure you want to delete this document?',
  ///   isDestructive: true,
  /// );
  /// if (confirmed) {
  ///   // Perform deletion
  /// }
  /// ```
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows an error dialog with an error message and optional details.
  ///
  /// [context] - The BuildContext to show the dialog in
  /// [title] - The error dialog title (default: 'Error')
  /// [message] - The error message to display
  /// [details] - Optional detailed error information (e.g., stack trace)
  ///
  /// Example:
  /// ```dart
  /// UIUtils.showErrorDialog(
  ///   context,
  ///   message: 'Failed to load document',
  ///   details: error.toString(),
  /// );
  /// ```
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String? details,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                details,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
