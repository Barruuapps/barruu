import 'package:logger/logger.dart';

/// Global logger instance for application-wide logging.
///
/// This logger is configured with sensible defaults for development and debugging:
/// - Pretty-printed output with colors and emojis
/// - Stack traces up to 2 methods for regular logs
/// - Stack traces up to 8 methods for errors
/// - Timestamps showing time and duration since start
/// - Line length limited to 80 characters
///
/// Usage:
/// ```dart
/// import 'package:barruu/core/utils/app_logger.dart';
///
/// // Log info messages
/// logger.i('User logged in successfully');
///
/// // Log warnings
/// logger.w('Network connection slow');
///
/// // Log errors with stack traces
/// logger.e('Failed to save document', error: e, stackTrace: stackTrace);
///
/// // Log debug messages
/// logger.d('Cache hit for key: $key');
/// ```
///
/// Log levels (in order of severity):
/// - `trace` (t): Very detailed information, typically for diagnosing issues
/// - `debug` (d): Detailed information for debugging
/// - `info` (i): General informational messages
/// - `warning` (w): Warning messages for potentially problematic situations
/// - `error` (e): Error messages for failures
/// - `wtf` (wtf): What a Terrible Failure - for critical issues that should never happen
final logger = Logger(
  printer: PrettyPrinter(
    lineLength: 80,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);