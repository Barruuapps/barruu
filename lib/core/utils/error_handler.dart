import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/ui_utils.dart';

/// Centralized error handling for consistent error logging and user feedback.
///
/// This class provides a single point for handling errors throughout the app:
/// - Logs errors to console/file
/// - Shows user-friendly messages
/// - Integrates with crash reporting (when configured)
/// - Tracks errors in analytics (when configured)
///
/// Usage:
/// ```dart
/// try {
///   await riskyOperation();
/// } catch (e, stackTrace) {
///   ErrorHandler.handle(
///     e,
///     stackTrace,
///     context: context,
///     userMessage: 'Failed to save document',
///   );
/// }
/// ```
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Handles an error by logging it and optionally showing it to the user.
  ///
  /// [error] - The error object
  /// [stackTrace] - The stack trace where the error occurred
  /// [context] - Optional BuildContext for showing UI feedback
  /// [showToUser] - Whether to show the error to the user (default: true)
  /// [userMessage] - Optional custom message to show to the user
  ///
  /// If [userMessage] is not provided, a user-friendly message will be
  /// generated based on the error type.
  ///
  /// Example:
  /// ```dart
  /// ErrorHandler.handle(
  ///   error,
  ///   stackTrace,
  ///   context: context,
  ///   userMessage: 'Failed to upload image',
  /// );
  /// ```
  static void handle(
    Object error,
    StackTrace stackTrace, {
    BuildContext? context,
    bool showToUser = true,
    String? userMessage,
  }) {
    // 1. Log to console/file
    logger.e('Error occurred', error: error, stackTrace: stackTrace);

    // 2. Send to crash reporting in release mode
    // TODO: Integrate with Firebase Crashlytics when configured
    // if (kReleaseMode) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // }

    // 3. Track in analytics
    // TODO: Integrate with analytics service when configured
    // AnalyticsService.instance.logEvent('error_occurred', {
    //   'error_type': error.runtimeType.toString(),
    //   'message': error.toString(),
    // });

    // 4. Show to user if needed
    if (showToUser && context != null && context.mounted) {
      final message = userMessage ?? _getUserFriendlyMessage(error);
      UIUtils.showSnackBar(context, message, isError: true);
    }
  }

  /// Handles an error and shows a detailed error dialog.
  ///
  /// Similar to [handle] but shows a dialog instead of a snackbar,
  /// which is better for critical errors that need more attention.
  ///
  /// Example:
  /// ```dart
  /// ErrorHandler.handleWithDialog(
  ///   error,
  ///   stackTrace,
  ///   context: context,
  ///   title: 'Critical Error',
  ///   message: 'Failed to initialize application',
  /// );
  /// ```
  static void handleWithDialog(
    Object error,
    StackTrace stackTrace, {
    required BuildContext context,
    String title = 'Error',
    String? message,
    bool showDetails = kDebugMode,
  }) {
    // Log the error
    logger.e(
      'Error occurred (showing dialog)',
      error: error,
      stackTrace: stackTrace,
    );

    // Show error dialog
    if (context.mounted) {
      UIUtils.showErrorDialog(
        context,
        title: title,
        message: message ?? _getUserFriendlyMessage(error),
        details: showDetails ? error.toString() : null,
      );
    }
  }

  /// Generates a user-friendly error message based on the error type.
  ///
  /// This uses simple string matching as a fallback mechanism. For production,
  /// consider creating custom exception types and checking instanceof instead.
  ///
  /// Future improvement: Create custom exception classes like NetworkException,
  /// StorageException, etc., and use type checking instead of string matching.
  static String _getUserFriendlyMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    // Storage/File errors
    if (errorString.contains('storage') ||
        errorString.contains('file') ||
        errorString.contains('directory')) {
      return 'Storage error. Please check available space.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized')) {
      return 'Permission denied. Please grant required permissions.';
    }

    // Format/Parsing errors
    if (errorString.contains('format') ||
        errorString.contains('parse') ||
        errorString.contains('json')) {
      return 'Invalid data format. Please try again.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('deadline')) {
      return 'Operation timed out. Please try again.';
    }

    // Default message
    return 'An unexpected error occurred. Please try again.';
  }
}
