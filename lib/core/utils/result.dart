import 'package:aurora_ledger/core/errors/failures.dart';

/// A simple Result type for explicit error handling without exceptions.
/// Use [Result.ok] for success, [Result.err] for failure.
///
/// Example:
/// ```dart
/// Result<String, Failure> result = await repository.doSomething();
/// result.when(
///   ok: (value) => print(value),
///   err: (failure) => print(failure.message),
/// );
/// ```
sealed class Result<T, E extends Failure> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E failure) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T get value => (this as Ok<T, E>).value;
  E get failure => (this as Err<T, E>).failure;

  R when<R>({
    required R Function(T value) ok,
    required R Function(E failure) err,
  }) {
    return switch (this) {
      Ok<T, E>(:final value) => ok(value),
      Err<T, E>(:final failure) => err(failure),
    };
  }

  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
        Ok<T, E>(:final value) => Result.ok(transform(value)),
        Err<T, E>(:final failure) => Result.err(failure),
      };
}

final class Ok<T, E extends Failure> extends Result<T, E> {
  const Ok(this.value);
  @override
  final T value;
}

final class Err<T, E extends Failure> extends Result<T, E> {
  const Err(this.failure);
  @override
  final E failure;
}
