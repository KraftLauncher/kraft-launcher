import 'package:meta/meta.dart';

@immutable
class MinecraftLoginResponse {
  const MinecraftLoginResponse({
    required this.username,
    required this.accessToken,
    required this.expiresIn,
  });

  final String username;
  final String accessToken;
  final int expiresIn;

  @override
  String toString() =>
      'MinecraftLoginResponse(username: $username, accessToken: $accessToken, expiresIn: $expiresIn)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MinecraftLoginResponse &&
        other.username == username &&
        other.accessToken == accessToken &&
        other.expiresIn == expiresIn;
  }

  @override
  int get hashCode => Object.hash(username, accessToken, expiresIn);
}
