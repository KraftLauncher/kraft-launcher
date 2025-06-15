import 'package:meta/meta.dart';

@immutable
sealed class MinecraftAccountResolverException implements Exception {
  const MinecraftAccountResolverException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class MinecraftJavaEntitlementAbsentException
    extends MinecraftAccountResolverException {
  const MinecraftJavaEntitlementAbsentException()
    : super(
        'The user does not possess the required Minecraft Java Edition entitlement for this account.',
      );
}
