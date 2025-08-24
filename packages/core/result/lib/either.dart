import 'package:meta/meta.dart';

@immutable
sealed class Either<L, R> {
  const Either();

  factory Either.left(L value) => EitherLeft(value);
  factory Either.right(R value) => EitherRight(value);
}

final class EitherLeft<L, R> extends Either<L, R> {
  const EitherLeft(this.leftValue);

  final L leftValue;
}

final class EitherRight<L, R> extends Either<L, R> {
  const EitherRight(this.rightValue);

  final R rightValue;
}
