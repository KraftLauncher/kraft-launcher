import 'dart:io';

import 'package:meta/meta.dart';

import '../../../common/logic/json.dart';
import '../microsoft_auth_api/microsoft_auth_api.dart'
    as microsoft_api
    show XboxLiveAuthTokenResponse;
import '../minecraft_account.dart';

@immutable
class MinecraftLoginResponse {
  const MinecraftLoginResponse({
    required this.username,
    required this.accessToken,
    required this.expiresIn,
  });

  factory MinecraftLoginResponse.fromJson(JsonObject json) =>
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

  factory MinecraftProfileResponse.fromJson(JsonObject json) =>
      MinecraftProfileResponse(
        id: json['id']! as String,
        name: json['name']! as String,
        skins:
            (json['skins']! as List<dynamic>)
                .cast<JsonObject>()
                .map((jsonObject) => MinecraftProfileSkin.fromJson(jsonObject))
                .toList(),
        capes:
            (json['capes']! as List<dynamic>)
                .cast<JsonObject>()
                .map((jsonObject) => MinecraftProfileCape.fromJson(jsonObject))
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
class MinecraftProfileSkin {
  const MinecraftProfileSkin({
    required this.id,
    required this.state,
    required this.url,
    required this.textureKey,
    required this.variant,
  });

  factory MinecraftProfileSkin.fromJson(JsonObject json) =>
      MinecraftProfileSkin(
        id: json['id']! as String,
        state: json['state']! as String,
        url: json['url']! as String,
        textureKey: json['textureKey']! as String,
        variant: MinecraftSkinVariant.fromJson(json['variant']! as String),
      );

  final String id;
  final String state;
  final String url;
  final String textureKey;
  final MinecraftSkinVariant variant;
}

@immutable
class MinecraftProfileCape {
  const MinecraftProfileCape({
    required this.id,
    required this.state,
    required this.url,
    required this.alias,
  });

  factory MinecraftProfileCape.fromJson(JsonObject json) =>
      MinecraftProfileCape(
        id: json['id']! as String,
        state: json['state']! as String,
        url: json['url']! as String,
        alias: json['alias']! as String,
      );

  final String id;
  final String state;
  final String url;
  final String alias;
}

abstract class MinecraftApi {
  Future<MinecraftLoginResponse> loginToMinecraftWithXbox(
    microsoft_api.XboxLiveAuthTokenResponse xsts,
  );

  /// [minecraftAccessToken] is the same as [MinecraftLoginResponse.accessToken]
  Future<MinecraftProfileResponse> fetchMinecraftProfile(
    String minecraftAccessToken,
  );

  Future<bool> checkMinecraftJavaOwnership(String minecraftAccessToken);

  // TODO: Handle the case where user don't have Microsoft account, account_creation_required will be thrown when calling: "https://xsts.auth.xboxlive.com/xsts/authorize", cover all cases
  // TODO: Create exception for an invalid skin file which is possible.
  Future<MinecraftProfileResponse> uploadSkin(
    File skinFile, {
    required MinecraftSkinVariant skinVariant,
    required String minecraftAccessToken,
  });
}
