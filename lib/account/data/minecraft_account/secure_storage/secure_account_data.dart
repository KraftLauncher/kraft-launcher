import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';

@immutable
class SecureAccountData extends Equatable {
  const SecureAccountData({
    required this.microsoftRefreshToken,
    required this.minecraftAccessToken,
  });

  factory SecureAccountData.fromJson(JsonObject json) => SecureAccountData(
    microsoftRefreshToken: json['msRefreshToken']! as String,
    minecraftAccessToken: json['mcAccessToken']! as String,
  );

  final String microsoftRefreshToken;
  final String minecraftAccessToken;

  JsonObject toJson() => {
    'msRefreshToken': microsoftRefreshToken,
    'mcAccessToken': minecraftAccessToken,
  };

  @override
  List<Object?> get props => [microsoftRefreshToken, minecraftAccessToken];
}
