import 'package:meta/meta.dart';

@immutable
class ExceptionWithStacktrace<T extends Exception> {
  const ExceptionWithStacktrace(this.exception, this.stackTrace);
  final T exception;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'Exception: $exception\nStack Trace: $stackTrace';
  }
}
