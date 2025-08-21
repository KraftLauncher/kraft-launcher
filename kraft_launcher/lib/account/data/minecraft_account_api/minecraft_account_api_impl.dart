import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api.dart';
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api_exceptions.dart'
    as minecraft_account_api_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/data/network/dio_helpers.dart';
import 'package:kraft_launcher/common/logic/file_utils.dart';

const _host = ApiHosts.minecraftServices;

// TODO: Replace MinecraftAccountApiImpl with a repository
//  that uses MinecraftServicesApiClient, https://github.com/KraftLauncher/kraft-launcher/issues/8

class MinecraftAccountApiImpl implements MinecraftAccountApi {
  MinecraftAccountApiImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

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
        throw const minecraft_account_api_exceptions.TooManyRequestsException();
      }

      if (e.response?.statusCode == HttpStatus.unauthorized) {
        throw const minecraft_account_api_exceptions.UnauthorizedException();
      }

      if (e.response?.statusCode == HttpStatus.serviceUnavailable) {
        throw const minecraft_account_api_exceptions.ServiceUnavailableException();
      }

      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;
      final errorMessage = errorBody?['errorMessage'] as String?;

      final exception = switch (code) {
        String() => minecraft_account_api_exceptions.UnknownException(
          'Code: $code, Details: ${errorMessage ?? 'The error description is not provided.'}',
          stackTrace,
        ),
        null => minecraft_account_api_exceptions.UnknownException(
          'The error code is not provided: ${e.response?.data}, ${e.response?.headers}',
          stackTrace,
        ),
      };
      throw exception;
    } on Exception catch (e, stackTrace) {
      // TODO: Avoid handling Exception in MicrosoftAuthApi and MinecraftAccountApi, DioException != HttpException like Ktor client, see also: https://pub.dev/packages/dio#handling-errors
      throw minecraft_account_api_exceptions.UnknownException(
        e.toString(),
        stackTrace,
      );
    }
  }

  @override
  Future<MinecraftLoginResponse> loginToMinecraftWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) async => _handleCommonFailures(() async {
    final response = await _dio.postUri<JsonMap>(
      Uri.https(_host, 'authentication/login_with_xbox'),
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
      final response = await _dio.getUri<JsonMap>(
        Uri.https(_host, 'minecraft/profile'),
        options: Options(
          headers: {'Authorization': 'Bearer $minecraftAccessToken'},
        ),
      );
      return MinecraftProfileResponse.fromJson(response.dataOrThrow);
    },
    customHandle: (e) {
      final errorBody = e.response?.data as JsonMap?;
      final code = errorBody?['error'] as String?;

      if (code == 'NOT_FOUND') {
        throw const minecraft_account_api_exceptions.AccountNotFoundException();
      }
      return null;
    },
  );

  @override
  Future<bool> checkMinecraftJavaOwnership(String minecraftAccessToken) =>
      _handleCommonFailures(() async {
        final response = await _dio.getUri<JsonMap>(
          Uri.https(_host, 'entitlements/mcstore'),
          options: Options(
            headers: {'Authorization': 'Bearer $minecraftAccessToken'},
          ),
        );
        return (response.dataOrThrow['items']! as JsonList).cast<JsonMap>().any(
          (itemMap) => (itemMap['name'] as String?) == 'game_minecraft',
        );
      });

  @override
  Future<MinecraftProfileResponse> uploadSkin(
    File skinFile, {
    required MinecraftApiSkinVariant skinVariant,
    required String minecraftAccessToken,
  }) => _handleCommonFailures(
    () async {
      final response = await _dio.postUri<JsonMap>(
        Uri.https(_host, 'minecraft/profile/skins'),
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
          throw const minecraft_account_api_exceptions.InvalidSkinImageDataException();
        }
      }
      return null;
    },
  );
}
