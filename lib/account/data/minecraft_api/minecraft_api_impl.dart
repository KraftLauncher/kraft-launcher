import 'dart:io';

import 'package:dio/dio.dart';

import '../../../common/logic/dio_client.dart';
import '../../../common/logic/file_utils.dart';
import '../../../common/logic/json.dart';
import 'minecraft_api.dart';
import 'minecraft_api_exceptions.dart';

class MinecraftApiImpl extends MinecraftApi {
  MinecraftApiImpl({required this.dio});

  final Dio dio;

  Future<T> _handleCommonFailures<T>(
    Future<T> Function() run, {
    T? Function(DioException e)? customHandle,
  }) async {
    try {
      return await run();
    } on DioException catch (e, stackTrace) {
      final customHandleResult = customHandle?.call(e);
      if (customHandleResult != null) {
        return customHandleResult;
      }

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
  Future<MinecraftLoginResponse> loginToMinecraftWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) async => _handleCommonFailures(() async {
    final response = await dio.postUri<JsonObject>(
      Uri.https('api.minecraftservices.com', '/authentication/login_with_xbox'),
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
      data: {'identityToken': 'XBL3.0 x=$xstsUserHash;$xstsToken'},
    );
    return MinecraftLoginResponse.fromJson(response.dataOrThrow);
  });

  @override
  Future<MinecraftProfileResponse> fetchMinecraftProfile(
    String minecraftAccessToken,
  ) async => _handleCommonFailures(
    () async {
      final response = await dio.getUri<JsonObject>(
        Uri.https('api.minecraftservices.com', '/minecraft/profile'),
        options: Options(
          headers: {'Authorization': 'Bearer $minecraftAccessToken'},
        ),
      );
      return MinecraftProfileResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonObject?;
      final code = errorBody?['error'] as String?;

      if (code == 'NOT_FOUND') {
        throw MinecraftApiException.accountNotFound();
      }
      return null;
    },
  );

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
    required MinecraftApiSkinVariant skinVariant,
    required String minecraftAccessToken,
  }) => _handleCommonFailures(
    () async {
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
            MinecraftApiSkinVariant.classic => 'classic',
            MinecraftApiSkinVariant.slim => 'slim',
          },
        }),
      );
      return MinecraftProfileResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      if (e.response?.statusCode == HttpStatus.badRequest) {
        final isInvalidSkinImageData =
            e.response?.data.toString().toLowerCase().contains(
              'Could not validate image data.'.toLowerCase(),
            ) ??
            false;
        if (isInvalidSkinImageData) {
          throw MinecraftApiException.invalidSkinImageData();
        }
      }
      return null;
    },
  );
}
