import 'package:meta/meta.dart';

@immutable
abstract class BaseFailure {
  const BaseFailure(this.message);

  // Used for debugging purposes and is not used in UI.
  final String message;

  @override
  String toString() => message;
}

@immutable
sealed class Result<V, F extends BaseFailure> {
  const Result();

  factory Result.success(V value) => SuccessResult(value);

  factory Result.failure(F failure) => FailureResult(failure);

  bool get isFailure => this is FailureResult;
  bool get isSuccess => this is SuccessResult;

  V? get valueOrNull =>
      this is SuccessResult<V, F> ? (this as SuccessResult<V, F>).value : null;
  F? get failureOrNull =>
      this is FailureResult<V, F>
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
}

final class SuccessResult<V, F extends BaseFailure> extends Result<V, F> {
  const SuccessResult(this.value);

  final V value;
}

final class FailureResult<V, F extends BaseFailure> extends Result<V, F> {
  const FailureResult(this.failure);

  final F failure;
}
