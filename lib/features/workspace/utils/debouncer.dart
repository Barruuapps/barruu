import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class that delays the execution of a callback until a specified
/// duration has passed since the last call.
///
/// Useful for preventing excessive function calls, such as when handling
/// text input changes or search queries.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Calls the callback after the delay. If called again before the delay
  /// expires, the previous call is cancelled and the timer resets.
  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancels any pending callback and disposes of the timer.
  void dispose() => _timer?.cancel();
}
