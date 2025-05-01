import 'dart:io';

import 'package:dio/dio.dart';

import '../../../common/logic/dio_client.dart';
import '../../../common/logic/file_utils.dart';
import '../../../common/logic/json.dart';
import '../microsoft_auth_api/microsoft_auth_api.dart'
    as microsoft_api
    show XboxLiveAuthTokenResponse;
import '../minecraft_account.dart';
import 'minecraft_api.dart';
import 'minecraft_api_exceptions.dart';

class MinecraftApiImpl extends MinecraftApi {
  MinecraftApiImpl({required this.dio});

  final Dio dio;

  Future<T> _handleCommonFailures<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e, stackTrace) {
      if (e.response?.statusCode == HttpStatus.tooManyRequests) {
        throw MinecraftApiException.tooManyRequests();
      }

      if (e.response?.statusCode == HttpStatus.unauthorized) {
        throw MinecraftApiException.unauthorized();
      }

      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;
      final errorMessage = errorBody?['errorMessage'] as String?;

      final exception = switch (code) {
        String() => MinecraftApiException.unknown(
          'Code: $code, Details: ${errorMessage ?? 'The error description is not provided.'}',
          stackTrace,
        ),
        null => MinecraftApiException.unknown(
          'The error code is not provided: ${e.response?.data}, ${e.response?.headers}',
          stackTrace,
        ),
      };
      throw exception;
    } on Exception catch (e, stackTrace) {
      throw MinecraftApiException.unknown(e.toString(), stackTrace);
    }
  }

  @override
  Future<MinecraftLoginResponse> loginToMinecraftWithXbox(
    microsoft_api.XboxLiveAuthTokenResponse xsts,
  ) async => _handleCommonFailures(() async {
    final response = await dio.postUri<JsonObject>(
      Uri.https('api.minecraftservices.com', '/authentication/login_with_xbox'),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
      data: {'identityToken': 'XBL3.0 x=${xsts.userHash};${xsts.xboxToken}'},
    );
    return MinecraftLoginResponse.fromJson(response.dataOrThrow);
  });

  @override
  Future<MinecraftProfileResponse> fetchMinecraftProfile(
    String minecraftAccessToken,
  ) async => _handleCommonFailures(() async {
    final response = await dio.getUri<JsonObject>(
      Uri.https('api.minecraftservices.com', '/minecraft/profile'),
      options: Options(
        headers: {'Authorization': 'Bearer $minecraftAccessToken'},
      ),
    );
    return MinecraftProfileResponse.fromJson(response.dataOrThrow);
  });

  @override
  Future<bool> checkMinecraftJavaOwnership(String minecraftAccessToken) =>
      _handleCommonFailures(() async {
        final response = await dio.getUri<JsonObject>(
          Uri.https('api.minecraftservices.com', '/entitlements/mcstore'),
          options: Options(
            headers: {'Authorization': 'Bearer $minecraftAccessToken'},
          ),
        );
        return (response.dataOrThrow['items']! as List<dynamic>)
            .cast<JsonObject>()
            .any(
              (jsonObject) =>
                  (jsonObject['name'] as String?) == 'game_minecraft',
            );
      });

  @override
  Future<MinecraftProfileResponse> uploadSkin(
    File skinFile, {
    required MinecraftSkinVariant skinVariant,
    required String minecraftAccessToken,
  }) => _handleCommonFailures(() async {
    final response = await dio.postUri<JsonObject>(
      Uri.https('api.minecraftservices.com', '/minecraft/profile/skins'),
      options: Options(
        headers: {'Authorization': 'Bearer $minecraftAccessToken'},
      ),
      data: FormData.fromMap({
        'file': MultipartFile.fromFileSync(
          skinFile.path,
          contentType: skinFile.mediaType,
        ),
        'variant': switch (skinVariant) {
          MinecraftSkinVariant.classic => 'classic',
          MinecraftSkinVariant.slim => 'slim',
        },
      }),
    );
    return MinecraftProfileResponse.fromJson(response.dataOrThrow);
  });
}
