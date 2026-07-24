import 'package:barruu/core/utils/result.dart';

/// Base class for all use cases in the application.
///
/// Use cases encapsulate business logic and orchestrate the flow of data
/// between the presentation layer and the data layer.
///
/// Type Parameters:
/// - [T]: The return type of the use case
/// - [Params]: The parameters required by the use case
abstract class UseCase<T, Params> {
  /// Executes the use case with the given parameters
  ///
  /// Returns a [Result] containing either the success value or an error
  Future<Result<T>> call(Params params);
}

/// Base class for use cases that don't require parameters
abstract class NoParamsUseCase<T> {
  /// Executes the use case without parameters
  ///
  /// Returns a [Result] containing either the success value or an error
  Future<Result<T>> call();
}
