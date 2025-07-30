import 'package:meta/meta.dart';

@immutable
abstract class BaseFailure {
  const BaseFailure(this.message);

  // Used for debugging purposes and is not used in UI.
  final String message;

  @override
  String toString() => message;
}

// See also: https://docs.flutter.dev/app-architecture/design-patterns/result
@immutable
sealed class Result<V, F extends BaseFailure> {
  const Result();

  factory Result.success(V value) => SuccessResult(value);

  factory Result.failure(F failure) => FailureResult(failure);

  // This uses [_Unit] as a substitute for `void` in generic result types,
  // since Dart does not support `void` as a value type like Kotlin's `Unit`.
  // The warning is safe to ignore because [_Unit] is intentionally used here
  // ignore: library_private_types_in_public_api
  static Result<_Unit, F> emptySuccess<F extends BaseFailure>() =>
      Result<_Unit, F>.success(_unit);

  bool get isFailure => this is FailureResult;
  bool get isSuccess => this is SuccessResult;

  V? get valueOrNull =>
      this is SuccessResult<V, F> ? (this as SuccessResult<V, F>).value : null;
  F? get failureOrNull => this is FailureResult<V, F>
      ? (this as FailureResult<V, F>).failure
      : null;

  V get valueOrThrow =>
      valueOrNull ??
      (throw StateError(
        'Expected the result to be in success state but was $runtimeType',
      ));
  F get failureOrThrow =>
      failureOrNull ??
      (throw StateError(
        'Expected the result to be in failure state but was $runtimeType',
      ));

  R fold<R>({
    required R Function(V value) onSuccess,
    required R Function(F failure) onFailure,
  }) => switch (this) {
    final SuccessResult<V, F> success => onSuccess(success.value),
    final FailureResult<V, F> failure => onFailure(failure.failure),
  };

  V getOrElse(V Function(F failure) onFailure) =>
      fold(onSuccess: (value) => value, onFailure: onFailure);

  /// Transforms a success value while preserving the failure type.
  Result<R, F> mapSuccess<R>(R Function(V value) transform) => switch (this) {
    final SuccessResult<V, F> success => Result.success(
      transform(success.value),
    ),
    final FailureResult<V, F> failure => Result.failure(failure.failure),
  };
}

final class SuccessResult<V, F extends BaseFailure> extends Result<V, F> {
  const SuccessResult(this.value);

  final V value;

  @override
  String toString() => 'Result<$V>.success($value)';
}

final class FailureResult<V, F extends BaseFailure> extends Result<V, F> {
  const FailureResult(this.failure);

  final F failure;

  @override
  String toString() => 'Result<$F>.failure($failure)';
}

class _Unit {
  const _Unit._();
}

const _unit = _Unit._();

typedef EmptyResult<F extends BaseFailure> = Result<_Unit, F>;

@visibleForTesting
typedef EmptySuccessResult<F extends BaseFailure> = SuccessResult<_Unit, F>;
