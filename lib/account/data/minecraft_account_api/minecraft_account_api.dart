/// @docImport 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
library;

import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

/// A client for the `api.minecraftservices.com` API.
///
/// See also:
///  * https://minecraft.wiki/w/Mojang_API
///  * [MicrosoftAuthApi]
abstract class MinecraftAccountApi {
  Future<MinecraftLoginResponse> loginToMinecraftWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  });

  /// [minecraftAccessToken] is the same as [MinecraftLoginResponse.accessToken]
  Future<MinecraftProfileResponse> fetchMinecraftProfile(
    String minecraftAccessToken,
  );

  Future<bool> checkMinecraftJavaOwnership(String minecraftAccessToken);

  Future<MinecraftProfileResponse> uploadSkin(
    File skinFile, {
    required MinecraftApiSkinVariant skinVariant,
    required String minecraftAccessToken,
  });
}

// TODO: Extract these models from this file, ensure they are close to the data source
//  (raw data or source data rather than an app model) and map them in one place
//  to follow Architecture. Make similar changes to all APIs, including MinecraftAccountApi and MicrosoftAuthApi

@immutable
class MinecraftLoginResponse {
  const MinecraftLoginResponse({
    required this.username,
    required this.accessToken,
    required this.expiresIn,
  });

  factory MinecraftLoginResponse.fromJson(JsonMap json) =>
      MinecraftLoginResponse(
        username: json['username']! as String,
        accessToken: json['access_token']! as String,
        expiresIn: json['expires_in']! as int,
      );

  final String username;
  final String accessToken;
  final int expiresIn;

  @override
  String toString() =>
      'MinecraftLoginResponse(username: $username, accessToken: $accessToken, expiresIn: $expiresIn)';
}

@immutable
class MinecraftProfileResponse {
  const MinecraftProfileResponse({
    required this.id,
    required this.name,
    required this.skins,
    required this.capes,
  });

  factory MinecraftProfileResponse.fromJson(JsonMap json) =>
      MinecraftProfileResponse(
        id: json['id']! as String,
        name: json['name']! as String,
        skins:
            (json['skins']! as JsonList)
                .cast<JsonMap>()
                .map((skinMap) => MinecraftProfileSkin.fromJson(skinMap))
                .toList(),
        capes:
            (json['capes']! as JsonList)
                .cast<JsonMap>()
                .map((capeMap) => MinecraftProfileCape.fromJson(capeMap))
                .toList(),
      );

  final String id;
  final String name;
  final List<MinecraftProfileSkin> skins;
  final List<MinecraftProfileCape> capes;

  @override
  String toString() =>
      'MinecraftProfile(id: $id, name: $name, skins: $skins, capes: $capes)';
}

@immutable
class MinecraftProfileSkin extends Equatable {
  const MinecraftProfileSkin({
    required this.id,
    required this.state,
    required this.url,
    required this.textureKey,
    required this.variant,
  });

  factory MinecraftProfileSkin.fromJson(JsonMap json) => MinecraftProfileSkin(
    id: json['id']! as String,
    state: MinecraftApiCosmeticState.fromJson(json['state']! as String),
    url: json['url']! as String,
    textureKey: json['textureKey']! as String,
    variant: MinecraftApiSkinVariant.fromJson(json['variant']! as String),
  );

  final String id;
  final MinecraftApiCosmeticState state;
  final String url;
  final String textureKey;
  final MinecraftApiSkinVariant variant;

  @override
  List<Object?> get props => [id, state, url, textureKey, variant];
}

@immutable
class MinecraftProfileCape extends Equatable {
  const MinecraftProfileCape({
    required this.id,
    required this.state,
    required this.url,
    required this.alias,
  });

  factory MinecraftProfileCape.fromJson(JsonMap json) => MinecraftProfileCape(
    id: json['id']! as String,
    state: MinecraftApiCosmeticState.fromJson(json['state']! as String),
    url: json['url']! as String,
    alias: json['alias']! as String,
  );

  final String id;
  final MinecraftApiCosmeticState state;
  final String url;
  final String alias;

  @override
  List<Object?> get props => [id, state, url, alias];
}

// TODO: Also rename the other classes if needed, solve the first TODO in this file
// TODO: Rename to ApiMinecraftSkinVariant to follow convnetions
enum MinecraftApiSkinVariant {
  classic,
  slim;

  static MinecraftApiSkinVariant fromJson(String json) => switch (json) {
    'CLASSIC' => classic,
    'SLIM' => slim,
    String() =>
      throw UnsupportedError(
        'Unknown Minecraft skin variant from the API: $json',
      ),
  };
}

// TODO: Rename to ApiMinecraftCosmeticState to follow convnetions
enum MinecraftApiCosmeticState {
  active,
  inactive;

  static MinecraftApiCosmeticState fromJson(String json) => switch (json) {
    'ACTIVE' => active,
    'INACTIVE' => inactive,
    String() =>
      throw UnsupportedError(
        'Unknown Minecraft cosmetic state from the API: $json',
      ),
  };
}
