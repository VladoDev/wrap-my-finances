import 'package:wrap_my_finances/core/errors/failure.dart';

/// A value that is either a successful [T] or a [Failure] — no exception
/// crosses a layer boundary (Constitution Principle 4). Pattern-match with a
/// `switch` over [Success]/[Failed], or use [when].
sealed class Result<T> {
  const Result();

  /// Reduces this [Result] to a single value of type [R].
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failed,
  }) => switch (this) {
    Success<T>(:final value) => success(value),
    Failed<T>(:final failure) => failed(failure),
  };
}

/// A successful [Result] carrying [value].
final class Success<T> extends Result<T> {
  /// Creates a successful result.
  const Success(this.value);

  /// The successful value.
  final T value;
}

/// A failed [Result] carrying the [failure] that occurred.
final class Failed<T> extends Result<T> {
  /// Creates a failed result.
  const Failed(this.failure);

  /// The failure that occurred.
  final Failure failure;
}
