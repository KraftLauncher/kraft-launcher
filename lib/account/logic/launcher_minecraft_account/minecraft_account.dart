import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum AccountType { microsoft, offline }

/// A model specific to this launcher, not part of the official Minecraft game or its APIs.
///
/// This model does **not** originate from the Minecraft game or any single API.
/// It is a custom format defined by this launcher to store relevant account data,
/// including values from multiple APIs.
///
/// Includes:
///
/// * The Minecraft access token
/// * The Microsoft refresh token
/// * Minecraft profile information (e.g., skin, capes, name, ID)
///
/// This format may vary between launchers. While the Minecraft game itself only
/// requires the access token and profile ID to launch, this model aggregates additional
/// data to support extended features such as refreshing the access token (using the
/// Microsoft refresh token) or managing the skin/profile.
@immutable
class MinecraftAccount extends Equatable {
  const MinecraftAccount({
    required this.id,
    required this.username,
    required this.accountType,
    required this.microsoftAccountInfo,
    required this.skins,
    required this.capes,
    required this.ownsMinecraftJava,
  });

  final String id;
  final String username;
  final AccountType accountType;

  /// Not null if [accountType] is [AccountType.microsoft].
  final MicrosoftAccountInfo? microsoftAccountInfo;

  // Skins and capes are always empty for offline accounts
  final List<MinecraftSkin> skins;
  final List<MinecraftCape> capes;

  MinecraftSkin? get activeSkin => skins.firstWhereOrNull(
    (skin) => skin.state == MinecraftCosmeticState.active,
  );

  /// Not null if [accountType] is [AccountType.microsoft].
  // Currently, this is always true and will never be false, but it will be useful
  // when adding support for demo mode.
  final bool? ownsMinecraftJava;

  bool get isMicrosoft => accountType == AccountType.microsoft;
  bool get isOffline => accountType == AccountType.offline;

  MinecraftAccount copyWith({
    String? id,
    String? username,
    AccountType? accountType,
    MicrosoftAccountInfo? microsoftAccountInfo,
    List<MinecraftSkin>? skins,
    List<MinecraftCape>? capes,
    bool? ownsMinecraftJava,
  }) => MinecraftAccount(
    id: id ?? this.id,
    username: username ?? this.username,
    accountType: accountType ?? this.accountType,
    microsoftAccountInfo: microsoftAccountInfo ?? this.microsoftAccountInfo,
    skins: skins ?? this.skins,
    capes: capes ?? this.capes,
    ownsMinecraftJava: ownsMinecraftJava ?? this.ownsMinecraftJava,
  );

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

enum MicrosoftReauthRequiredReason {
  accessRevoked,
  refreshTokenExpired,
  tokensMissingFromSecureStorage,
  tokensMissingFromFileStorage,
}

@immutable
class MicrosoftAccountInfo extends Equatable {
  const MicrosoftAccountInfo({
    required this.microsoftRefreshToken,
    required this.minecraftAccessToken,
    required this.reauthRequiredReason,
  });

  // TODO: We could consider changing the way we're storing token dates if needed,
  //  for example, storing issues at for both + expiresIn for the Minecraft access token

  // NOTE: The Microsoft API doesn't provide the expiration date for the refresh token,
  // it's 90 days according to https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens#token-lifetime.
  // The app will always need to handle the case where it's expired or access is revoked when sending the request.
  final ExpirableToken microsoftRefreshToken;

  final ExpirableToken minecraftAccessToken;

  final MicrosoftReauthRequiredReason? reauthRequiredReason;

  bool get needsReAuth => reauthRequiredReason != null;

  MicrosoftAccountInfo copyWith({
    ExpirableToken? microsoftRefreshToken,
    ExpirableToken? minecraftAccessToken,
    MicrosoftReauthRequiredReason? reauthRequiredReason,
  }) {
    return MicrosoftAccountInfo(
      microsoftRefreshToken:
          microsoftRefreshToken ?? this.microsoftRefreshToken,
      minecraftAccessToken: minecraftAccessToken ?? this.minecraftAccessToken,
      reauthRequiredReason: reauthRequiredReason ?? this.reauthRequiredReason,
    );
  }

  @override
  List<Object?> get props => [
    microsoftRefreshToken,
    minecraftAccessToken,
    reauthRequiredReason,
  ];
}

@immutable
class ExpirableToken extends Equatable {
  const ExpirableToken({required this.value, required this.expiresAt});

  /// Null if the token is not found in either secure storage or file storage.
  final String? value;
  final DateTime expiresAt;

  ExpirableToken copyWith({String? value, DateTime? expiresAt}) {
    return ExpirableToken(
      value: value ?? this.value,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [value, expiresAt];
}

enum MinecraftSkinVariant { classic, slim }

// For both skins and capes.
enum MinecraftCosmeticState { active, inactive }

@immutable
class MinecraftSkin extends Equatable {
  const MinecraftSkin({
    required this.id,
    required this.state,
    required this.url,
    required this.textureKey,
    required this.variant,
  });

  final String id;
  final MinecraftCosmeticState state;
  final String url;
  final String textureKey;
  final MinecraftSkinVariant variant;

  @override
  List<Object?> get props => [id, state, url, textureKey, variant];
}

@immutable
class MinecraftCape extends Equatable {
  const MinecraftCape({
    required this.id,
    required this.state,
    required this.url,
    required this.alias,
  });

  final String id;
  final MinecraftCosmeticState state;
  final String url;
  final String alias;

  @override
  List<Object?> get props => [id, state, url, alias];
}
