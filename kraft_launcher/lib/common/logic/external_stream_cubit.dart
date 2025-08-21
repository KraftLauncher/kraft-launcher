import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

/// A [Cubit] that manages subscriptions to external streams and emits new
/// states in response to stream events.
///
/// Use [forEach] to subscribe to a [Stream] and emit updated states when
/// the stream emits data or errors. Subscriptions are automatically
/// cancelled when the cubit is closed.
///
/// Example:
///
/// ```dart
/// forEach<int>(
///   accountsStream,
///   onData: (accounts) => state.copyWith(accounts: accounts),
///   onError: (error, stackTrace) => state.copyWith(error: error),
/// );
/// ```
///
/// See also:
///
/// * https://bloclibrary.dev/architecture/#connecting-blocs-through-domain, an example of `forEach` from `Bloc`.
/// * https://pub.dev/documentation/bloc/latest/bloc/Emitter/forEach.html, the API docs of `forEach` from `Bloc`.
abstract class ExternalStreamCubit<State> extends Cubit<State> {
  ExternalStreamCubit(super.initialState);

  final List<StreamSubscription<Object?>> _subscriptions = [];

  @visibleForTesting
  List<StreamSubscription<Object?>> get subscriptions => _subscriptions;

  set subscriptions(List<StreamSubscription<Object?>> value) {
    _subscriptions.clear();
    _subscriptions.addAll(value);
  }

  // Similar to https://pub.dev/documentation/bloc/latest/bloc/Emitter/forEach.html
  // but for Cubits.
  void forEach<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
    State Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final subscription = stream.listen(
      (data) {
        final newState = onData(data);
        emit(newState);
      },
      onError: onError != null
          ? (Object error, StackTrace stackTrace) {
              final newState = onError(error, stackTrace);
              emit(newState);
            }
          : null,
    );
    _subscriptions.add(subscription);
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
