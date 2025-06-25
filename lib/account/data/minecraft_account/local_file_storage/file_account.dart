import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';
import '../minecraft_account.dart'
    show
        AccountType,
        MinecraftCape,
        MinecraftCosmeticState,
        MinecraftSkin,
        MinecraftSkinVariant;

@immutable
class FileAccount extends Equatable {
  const FileAccount({
    required this.id,
    required this.username,
    required this.accountType,
    required this.microsoftAccountInfo,
    required this.skins,
    required this.capes,
    required this.ownsMinecraftJava,
  });

  factory FileAccount.fromJson(JsonMap json) => FileAccount(
    id: json['id']! as String,
    accountType: _AccountTypeJson.fromJson(json['accountType']! as String),
    username: json['username']! as String,
    microsoftAccountInfo: () {
      final jsonObject = json['microsoftAccountInfo'] as JsonMap?;
      if (jsonObject == null) {
        return null;
      }
      return FileMicrosoftAccountInfo.fromJson(jsonObject);
    }(),
    skins:
        (json['skins']! as List<dynamic>)
            .cast<JsonMap>()
            .map((jsonObject) => _MinecraftSkinJson.fromJson(jsonObject))
            .toList(),
    capes:
        (json['capes']! as List<dynamic>)
            .cast<JsonMap>()
            .map((jsonObject) => _MinecraftCapeJson.fromJson(jsonObject))
            .toList(),
    ownsMinecraftJava: json['ownsMinecraftJava'] as bool?,
  );

  final String id;
  final String username;
  final AccountType accountType;

  final FileMicrosoftAccountInfo? microsoftAccountInfo;

  final List<MinecraftSkin> skins;
  final List<MinecraftCape> capes;

  final bool? ownsMinecraftJava;

  JsonMap toJson() => {
    'id': id,
    'username': username,
    'accountType': accountType.toJson(),
    'microsoftAccountInfo': microsoftAccountInfo?.toJson(),
    'skins': skins.map((skin) => skin.toJson()).toList(),
    'capes': capes.map((cape) => cape.toJson()).toList(),
    'ownsMinecraftJava': ownsMinecraftJava,
  };

  @override
  List<Object?> get props => [
    id,
    username,
    accountType,
    microsoftAccountInfo,
    skins,
    capes,
    ownsMinecraftJava,
  ];
}

@immutable
class FileMicrosoftAccountInfo extends Equatable {
  const FileMicrosoftAccountInfo({
    required this.microsoftRefreshToken,
    required this.minecraftAccessToken,
    required this.accessRevoked,
  });

  factory FileMicrosoftAccountInfo.fromJson(JsonMap json) =>
      FileMicrosoftAccountInfo(
        microsoftRefreshToken: FileExpirableToken.fromJson(
          json['microsoftRefreshToken']! as JsonMap,
        ),
        minecraftAccessToken: FileExpirableToken.fromJson(
          json['minecraftAccessToken']! as JsonMap,
        ),
        accessRevoked: json['accessRevoked']! as bool,
      );

  final FileExpirableToken microsoftRefreshToken;
  final FileExpirableToken minecraftAccessToken;

  /// Whether the Microsoft access was revoked by the user. This is set to true
  /// when a request is sent and the API denies the request before the expiration
  /// of [microsoftRefreshToken].
  final bool accessRevoked;

  JsonMap toJson() => {
    'microsoftRefreshToken': microsoftRefreshToken.toJson(),
    'minecraftAccessToken': minecraftAccessToken.toJson(),
    'accessRevoked': accessRevoked,
  };

  bool get hasMissingTokens =>
      microsoftRefreshToken.value == null || minecraftAccessToken.value == null;

  @override
  List<Object?> get props => [
    microsoftRefreshToken,
    minecraftAccessToken,
    accessRevoked,
  ];
}

@immutable
class FileExpirableToken extends Equatable {
  const FileExpirableToken({required this.value, required this.expiresAt});

  factory FileExpirableToken.fromJson(JsonMap json) => FileExpirableToken(
    expiresAt: DateTime.parse(json['expiresAt']! as String),
    value: json['value'] as String?,
  );

  final String? value;
  // TODO: Should we consider storing issuedAt and expiresIn instead?
  final DateTime expiresAt;

  JsonMap toJson() => {
    'value': value,
    'expiresAt': expiresAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [value, expiresAt];
}

extension _MinecraftCapeJson on MinecraftCape {
  static MinecraftCape fromJson(JsonMap json) => MinecraftCape(
    id: json['id']! as String,
    state: _MinecraftCosmeticStateJson.fromJson(json['state']! as String),
    url: json['url']! as String,
    alias: json['alias']! as String,
  );

  JsonMap toJson() => {
    'id': id,
    'state': switch (state) {
      MinecraftCosmeticState.active => 'active',
      MinecraftCosmeticState.inactive => 'inactive',
    },
    'url': url,
    'alias': alias,
  };
}

extension _MinecraftSkinJson on MinecraftSkin {
  static MinecraftSkin fromJson(JsonMap json) => MinecraftSkin(
    id: json['id']! as String,
    state: _MinecraftCosmeticStateJson.fromJson(json['state']! as String),
    textureKey: json['textureKey']! as String,
    url: json['url']! as String,
    variant: () {
      final skinVariant = json['variant']! as String;
      return switch (skinVariant) {
        'classic' => MinecraftSkinVariant.classic,
        'slim' => MinecraftSkinVariant.slim,
        String() =>
          throw UnsupportedError(
            'Unknown Minecraft skin variant: $skinVariant',
          ),
      };
    }(),
  );

  JsonMap toJson() => {
    'id': id,
    'state': state.toJson(),
    'url': url,
    'textureKey': textureKey,
    'variant': switch (variant) {
      MinecraftSkinVariant.classic => 'classic',
      MinecraftSkinVariant.slim => 'slim',
    },
  };
}

extension _MinecraftCosmeticStateJson on MinecraftCosmeticState {
  String toJson() => switch (this) {
    MinecraftCosmeticState.active => 'active',
    MinecraftCosmeticState.inactive => 'inactive',
  };

  static MinecraftCosmeticState fromJson(String json) => switch (json) {
    'active' => MinecraftCosmeticState.active,
    'inactive' => MinecraftCosmeticState.inactive,
    String() =>
      throw UnsupportedError('Unknown Minecraft cosmetic state: $json'),
  };
}

extension _AccountTypeJson on AccountType {
  static AccountType fromJson(String json) => switch (json) {
    'microsoft' => AccountType.microsoft,
    'offline' => AccountType.offline,
    String() => throw UnsupportedError('Unknown Minecraft account type: $json'),
  };

  String toJson() => switch (this) {
    AccountType.microsoft => 'microsoft',
    AccountType.offline => 'offline',
  };
}
