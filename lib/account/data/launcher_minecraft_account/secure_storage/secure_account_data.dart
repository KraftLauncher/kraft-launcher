import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class SecureAccountData extends Equatable {
  const SecureAccountData({
    required this.microsoftRefreshToken,
    required this.minecraftAccessToken,
  });

  factory SecureAccountData.fromJson(JsonMap json) => SecureAccountData(
    microsoftRefreshToken: json['msRefreshToken']! as String,
    minecraftAccessToken: json['mcAccessToken']! as String,
  );

  final String microsoftRefreshToken;
  final String minecraftAccessToken;

  JsonMap toJson() => {
    'msRefreshToken': microsoftRefreshToken,
    'mcAccessToken': minecraftAccessToken,
  };

  @override
  List<Object?> get props => [microsoftRefreshToken, minecraftAccessToken];
}
