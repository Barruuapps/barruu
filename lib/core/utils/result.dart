/// A type-safe result wrapper for operations that can succeed or fail.
///
/// This provides a functional approach to error handling, making errors
/// explicit in the type system and avoiding exceptions for expected failures.
///
/// Usage:
/// ```dart
/// // Returning a result
/// Future<Result<Document>> loadDocument(String id) async {
///   try {
///     final doc = await repository.getDocument(id);
///     return Result.success(doc);
///   } catch (e) {
///     return Result.error('Failed to load document: ${e.toString()}');
///   }
/// }
///
/// // Handling a result
/// final result = await loadDocument('123');
/// result.when(
///   success: (doc) => print('Loaded: ${doc.title}'),
///   error: (msg) => print('Error: $msg'),
/// );
///
/// // Or using pattern matching
/// switch (result) {
///   case Success(value: final doc):
///     print('Loaded: ${doc.title}');
///   case Error(message: final msg):
///     print('Error: $msg');
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful result with the given value.
  factory Result.success(T value) = Success<T>;

  /// Creates an error result with the given message.
  factory Result.error(String message) = Error<T>;

  /// Returns true if this is a successful result.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is an error result.
  bool get isError => this is Error<T>;

  /// Executes one of the provided callbacks based on the result type.
  ///
  /// Example:
  /// ```dart
  /// result.when(
  ///   success: (value) => handleSuccess(value),
  ///   error: (message) => handleError(message),
  /// );
  /// ```
  R when<R>({
    required R Function(T value) success,
    required R Function(String message) error,
  }) {
    return switch (this) {
      Success(value: final v) => success(v),
      Error(message: final m) => error(m),
    };
  }

  /// Maps the success value to a new type while preserving errors.
  ///
  /// Example:
  /// ```dart
  /// Result<int> number = Result.success(5);
  /// Result<String> text = number.map((n) => n.toString());
  /// ```
  Result<R> map<R>(R Function(T value) transform) {
    return when(
      success: (value) => Result.success(transform(value)),
      error: (message) => Result.error(message),
    );
  }

  /// Chains multiple operations that return Results.
  ///
  /// Example:
  /// ```dart
  /// final result = await loadDocument('123')
  ///   .flatMap((doc) => validateDocument(doc))
  ///   .flatMap((doc) => saveDocument(doc));
  /// ```
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return when(
      success: transform,
      error: (message) => Result.error(message),
    );
  }

  /// Gets the success value or returns the provided default.
  ///
  /// Example:
  /// ```dart
  /// final doc = result.getOrElse(Document.empty());
  /// ```
  T getOrElse(T defaultValue) {
    return when(
      success: (value) => value,
      error: (_) => defaultValue,
    );
  }

  /// Gets the success value or null if this is an error.
  ///
  /// Example:
  /// ```dart
  /// final doc = result.getOrNull();
  /// if (doc != null) { /* use doc */ }
  /// ```
  T? getOrNull() {
    return when(
      success: (value) => value,
      error: (_) => null,
    );
  }

  /// Gets the error message or null if this is a success.
  ///
  /// Example:
  /// ```dart
  /// final error = result.errorOrNull();
  /// if (error != null) { /* handle error */ }
  /// ```
  String? errorOrNull() {
    return when(
      success: (_) => null,
      error: (message) => message,
    );
  }
}

/// A successful result containing a value.
final class Success<T> extends Result<T> {
  /// The successful value.
  final T value;

  /// Creates a successful result with the given value.
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// An error result containing an error message.
final class Error<T> extends Result<T> {
  /// The error message describing what went wrong.
  final String message;

  /// Creates an error result with the given message.
  const Error(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Error($message)';
}
