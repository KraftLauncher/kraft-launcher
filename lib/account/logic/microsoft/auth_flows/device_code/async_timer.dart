import 'dart:async';

// TODO: Write tests for this? If it's only for MicrosoftDeviceCodeFlow, it might not be needed since there are tests for this

class AsyncTimer<T> {
  AsyncTimer({required this.timer});

  factory AsyncTimer.periodic(Duration duration, void Function() callback) =>
      AsyncTimer<T>(timer: Timer.periodic(duration, (timer) => callback()));

  final Timer timer;
  final Completer<T?> completer = Completer<T>();

  bool get isActive => timer.isActive;

  Future<T?> awaitTimer() => completer.future;

  void cancel(T result) {
    timer.cancel();

    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }
}
