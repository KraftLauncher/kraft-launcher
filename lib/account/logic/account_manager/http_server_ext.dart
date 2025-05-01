import 'dart:async';
import 'dart:io';

extension HttpServerExt on HttpServer {
  Future<HttpRequest?> get firstOrNull {
    final completer = Completer<HttpRequest?>();
    late StreamSubscription<HttpRequest> serverSubscription;

    serverSubscription = listen(
      (request) {
        if (!completer.isCompleted) {
          completer.complete(request);
          serverSubscription.cancel();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }
}
