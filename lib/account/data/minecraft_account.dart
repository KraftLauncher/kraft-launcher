import 'package:meta/meta.dart';

import '../../common/logic/json.dart';
import '../../common/logic/utils.dart';
import 'microsoft_auth_api/microsoft_auth_api.dart';
import 'minecraft_api/minecraft_api.dart';

enum AccountType { microsoft, offline }

@immutable
class MinecraftAccount {
  const MinecraftAccount({
    required this.id,
    required this.username,
    required this.accountType,
    required this.microsoftAccountInfo,
    required this.skins,
    required this.ownsMinecraftJava,
  });

  factory MinecraftAccount.fromMinecraftProfileResponse({
    required MinecraftProfileResponse profileResponse,
    required MicrosoftOauthTokenExchangeResponse oauthTokenResponse,
    required MinecraftLoginResponse loginResponse,
    required bool ownsMinecraftJava,
  }) => MinecraftAccount(
    id: profileResponse.id,
    username: profileResponse.name,
    accountType: AccountType.microsoft,
    microsoftAccountInfo: MicrosoftAccountInfo(
      microsoftOAuthAccessToken: ExpirableToken(
        value: oauthTokenResponse.accessToken,
        expiresAt: expiresInToExpiresAt(oauthTokenResponse.expiresIn),
      ),
      microsoftOAuthRefreshToken: oauthTokenResponse.refreshToken,
      minecraftAccessToken: ExpirableToken(
        value: loginResponse.accessToken,
        expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
      ),
    ),
    skins:
        profileResponse.skins
            .map(
              (skin) => MinecraftSkin(
                id: skin.id,
                state: skin.state,
                url: skin.url,
                textureKey: skin.textureKey,
                variant: skin.variant,
              ),
            )
            .toList(),
    ownsMinecraftJava: ownsMinecraftJava,
  );

  factory MinecraftAccount.fromJson(JsonObject json) => MinecraftAccount(
    id: json['id']! as String,
    accountType: AccountType.values.firstWhere(
      (accountType) => accountType.name == (json['accountType']! as String),
    ),
    username: json['username']! as String,
    microsoftAccountInfo: () {
      final jsonObject = json['microsoftAccountInfo'] as JsonObject?;
      if (jsonObject == null) {
        return null;
      }
      return MicrosoftAccountInfo.fromJson(jsonObject);
    }(),
    skins:
        (json['skins']! as List<dynamic>)
            .cast<JsonObject>()
            .map((jsonObject) => MinecraftSkin.fromJson(jsonObject))
            .toList(),
    ownsMinecraftJava: json['ownsMinecraftJava'] as bool?,
  );

  final String id;
  final String username;
  final AccountType accountType;

  /// Not null if [accountType] is [AccountType.microsoft].
  final MicrosoftAccountInfo? microsoftAccountInfo;

  final List<MinecraftSkin> skins;

  MinecraftSkin get activeSkin =>
      skins.firstWhere((skin) => skin.state == 'ACTIVE');

  /// Not null if [accountType] is [AccountType.microsoft].
  final bool? ownsMinecraftJava;

  bool get isMicrosoft => accountType == AccountType.microsoft;

  JsonObject toJson() => {
    'id': id,
    'username': username,
    'accountType': accountType.name,
    'microsoftAccountInfo': microsoftAccountInfo?.toJson(),
    'skins': skins.map((skin) => skin.toJson()).toList(),
    'ownsMinecraftJava': ownsMinecraftJava,
  };

  MinecraftAccount copyWith({
    String? id,
    String? username,
    AccountType? accountType,
    MicrosoftAccountInfo? microsoftAccountInfo,
    List<MinecraftSkin>? skins,
    bool? ownsMinecraftJava,
  }) => MinecraftAccount(
    id: id ?? this.id,
    username: username ?? this.username,
    accountType: accountType ?? this.accountType,
    microsoftAccountInfo: microsoftAccountInfo ?? this.microsoftAccountInfo,
    skins: skins ?? this.skins,
    ownsMinecraftJava: ownsMinecraftJava ?? this.ownsMinecraftJava,
  );
}

@immutable
class MicrosoftAccountInfo {
  const MicrosoftAccountInfo({
    required this.microsoftOAuthAccessToken,
    required this.microsoftOAuthRefreshToken,
    required this.minecraftAccessToken,
  });

  factory MicrosoftAccountInfo.fromJson(JsonObject json) =>
      MicrosoftAccountInfo(
        microsoftOAuthAccessToken: ExpirableToken.fromJson(
          json['microsoftOAuthAccessToken']! as JsonObject,
        ),
        microsoftOAuthRefreshToken:
            json['microsoftOAuthRefreshToken']! as String,
        minecraftAccessToken: ExpirableToken.fromJson(
          json['minecraftAccessToken']! as JsonObject,
        ),
      );

  final ExpirableToken microsoftOAuthAccessToken;

  // It's unknown when the OAuth refresh token expires. See https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens#token-lifetime
  final String microsoftOAuthRefreshToken;

  final ExpirableToken minecraftAccessToken;

  JsonObject toJson() => {
    'microsoftOAuthAccessToken': microsoftOAuthAccessToken.toJson(),
    'microsoftOAuthRefreshToken': microsoftOAuthRefreshToken,
    'minecraftAccessToken': minecraftAccessToken.toJson(),
  };
}

@immutable
class ExpirableToken {
  const ExpirableToken({required this.value, required this.expiresAt});

  factory ExpirableToken.fromJson(JsonObject json) => ExpirableToken(
    expiresAt: DateTime.parse(json['expiresAt']! as String),
    value: json['value']! as String,
  );

  final String value;
  final DateTime expiresAt;

  JsonObject toJson() => {
    'value': value,
    'expiresAt': expiresAt.toIso8601String(),
  };

  bool get hasExpired => expiresAt.isBefore(DateTime.now());
}

enum MinecraftSkinVariant {
  classic,
  slim;

  static MinecraftSkinVariant fromJson(String json) => values.firstWhere(
    (variant) => json.toLowerCase() == variant.name.toLowerCase(),
  );
}

@immutable
class MinecraftSkin {
  const MinecraftSkin({
    required this.id,
    required this.state,
    required this.url,
    required this.textureKey,
    required this.variant,
  });

  factory MinecraftSkin.fromJson(JsonObject json) => MinecraftSkin(
    id: json['id']! as String,
    state: json['state']! as String,
    textureKey: json['textureKey']! as String,
    url: json['url']! as String,
    variant: MinecraftSkinVariant.fromJson(json['variant']! as String),
  );

  final String id;
  final String state;
  final String url;
  final String textureKey;

  final MinecraftSkinVariant variant;

  JsonObject toJson() => {
    'id': id,
    'state': state,
    'url': url,
    'textureKey': textureKey,
    'variant': variant.name,
  };
}
