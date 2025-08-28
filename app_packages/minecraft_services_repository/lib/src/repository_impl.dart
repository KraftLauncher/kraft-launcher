import 'dart:typed_data';

import 'package:app_api_client_utils/app_api_client_utils.dart';
import 'package:minecraft_services_client/minecraft_services_client.dart'
    as client;
import 'package:minecraft_services_repository/src/failures.dart';
import 'package:minecraft_services_repository/src/models/models.dart';
import 'package:minecraft_services_repository/src/repository.dart';

final class DefaultMinecraftServicesRepository
    implements MinecraftServicesRepository {
  DefaultMinecraftServicesRepository({
    required client.MinecraftServicesApiClient apiClient,
  }) : _apiClient = apiClient;

  final client.MinecraftServicesApiClient _apiClient;

  @override
  Future<MinecraftServicesResult<MinecraftLoginResponse>> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) async {
    final result = await _apiClient.authenticateWithXbox(
      xstsToken: xstsToken,
      xstsUserHash: xstsUserHash,
    );

    return result.map(
      onSuccess: (value) => value.body._toDomain(),
      onFailure: _toDomainFailure,
    );
  }

  @override
  Future<MinecraftServicesResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  }) async {
    final result = await _apiClient.fetchProfile(accessToken: accessToken);

    return result.map(
      onSuccess: (value) => value.body._toDomain(),
      onFailure: (failure) => _toDomainFailure(
        failure,
        overrideHttpFailure: (response) {
          if (response.body.isAccountNotFound) {
            return const AccountNotFoundFailure();
          }
          return null;
        },
      ),
    );
  }

  @override
  Future<MinecraftServicesResult<bool>> hasValidMinecraftJavaLicense({
    required String accessToken,
  }) async {
    final result = await _apiClient.fetchEntitlements(accessToken: accessToken);
    return result.map(
      onSuccess: (value) {
        final items = value.body.items;
        const requiredNames = {'product_minecraft', 'game_minecraft'};

        return requiredNames.every(
          (name) => items.any((item) => item.name == name),
        );
      },
      onFailure: _toDomainFailure,
    );
  }

  @override
  Future<MinecraftServicesResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required Uint8List skinBytes,
    required MinecraftSkinVariant variant,
  }) async {
    _validateSkinSize(skinBytes);

    final result = await _apiClient.uploadSkin(
      accessToken: accessToken,
      skinFile: client.MultipartFile.fromBytes(
        'file',
        skinBytes,
        contentType: client.MediaType('image', 'png'),
      ),
      variant: variant._toDto(),
    );
    return result.map(
      onSuccess: (value) => value.body._toDomain(),
      onFailure: (failure) => _toDomainFailure(
        failure,
        overrideHttpFailure: (response) {
          if (response.statusCode == client.HttpStatusCodes.badRequest &&
              response.body.isCouldNotValidateSkinImageData) {
            return const InvalidSkinImageDataFailure();
          }
          return null;
        },
      ),
    );
  }

  /// Converts a [client.ApiFailure] containing a [client.MinecraftErrorResponse]
  /// from the API client into a domain-level [MinecraftServicesFailure].
  ///
  /// Optionally, a [overrideHttpFailure] can be provided to customize
  /// how the HTTP response is mapped.
  MinecraftServicesFailure _toDomainFailure(
    client.ApiFailure<client.MinecraftErrorResponse> failure, {
    _HttpFailureOverride? overrideHttpFailure,
  }) => failure._toDomain(overrideHttpFailure);

  void _validateSkinSize(Uint8List skinBytes) {
    const maxSkinSizeInKb = MinecraftServicesRepository.maxSkinSizeInKb;
    const maxSkinSizeInBytes = maxSkinSizeInKb * 1024;

    // NOTE: This validation is not unit-tested because it has minimal risk and limited value.
    if (skinBytes.lengthInBytes > maxSkinSizeInBytes) {
      throw ArgumentError('Skin file size must not exceed $maxSkinSizeInKb KB');
    }
  }
}

// Mappers

typedef _HttpFailureOverride =
    MinecraftServicesFailure? Function(
      client.HttpResponse<client.MinecraftErrorResponse> response,
    );

extension _ApiFailureDomainMapper
    on client.ApiFailure<client.MinecraftErrorResponse> {
  MinecraftServicesFailure _toDomain(
    _HttpFailureOverride? overrideHttpFailure,
  ) {
    final failure = this;
    return switch (failure) {
      client.ConnectionFailure<client.MinecraftErrorResponse>() =>
        ConnectionFailure(failure.message),
      client.HttpStatusFailure<client.MinecraftErrorResponse>(
        :final response,
      ) =>
        mapHttpStatusToFailure(
          statusCode: response.statusCode,
          headers: response.headers,
          onTooManyRequests: () => const TooManyRequestsFailure(),
          onUnauthorized: () => const UnauthorizedAccessFailure(),
          onServiceUnavailable: (retryAfterInSeconds) =>
              ServiceUnavailableFailure(
                retryAfterInSeconds: retryAfterInSeconds,
              ),
          onInternalServerError: () => InternalServerFailure(
            response.body.errorMessage,
            response.statusCode,
          ),
          override: () => overrideHttpFailure?.call(response),
          orElse: () => UnhandledServerResponseFailure(
            response.statusCode,
            response.body.errorMessage,
          ),
        ),
      client.UnexpectedFailure<client.MinecraftErrorResponse>() =>
        UnexpectedFailure(failure.message),
      client.JsonDecodingFailure<client.MinecraftErrorResponse>(
        :final responseBody,
        :final reason,
      ) =>
        InvalidDataFormatFailure(responseBody, reason),
      client.JsonDeserializationFailure<client.MinecraftErrorResponse>(
        :final decodedJson,
        :final reason,
      ) =>
        UnexpectedDataStructureFailure(decodedJson, reason),
    };
  }
}

extension _MinecraftProfileDomainMapper on client.MinecraftProfileResponse {
  MinecraftProfileResponse _toDomain() => MinecraftProfileResponse(
    id: id,
    name: name,
    skins: skins.map((skin) => skin._toDomain()).toList(),
    capes: capes.map((cape) => cape._toDomain()).toList(),
  );
}

extension _MinecraftLoginDomainMapper on client.MinecraftLoginResponse {
  MinecraftLoginResponse _toDomain() => MinecraftLoginResponse(
    username: username,
    accessToken: accessToken,
    expiresIn: expiresIn,
  );
}

extension _MinecraftCosmeticStateDomainMapper on client.MinecraftCosmeticState {
  MinecraftCosmeticState _toDomain() => switch (this) {
    client.MinecraftCosmeticState.active => MinecraftCosmeticState.active,
    client.MinecraftCosmeticState.inactive => MinecraftCosmeticState.inactive,
  };
}

extension _MinecraftProfileSkinDomainMapper on client.MinecraftProfileSkin {
  MinecraftProfileSkin _toDomain() => MinecraftProfileSkin(
    id: id,
    textureKey: textureKey,
    url: url,
    variant: variant._toDomain(),
    state: state._toDomain(),
  );
}

extension _MinecraftSkinVariantDtoMapper on MinecraftSkinVariant {
  client.MinecraftSkinVariant _toDto() => switch (this) {
    MinecraftSkinVariant.classic => client.MinecraftSkinVariant.classic,
    MinecraftSkinVariant.slim => client.MinecraftSkinVariant.slim,
  };
}

extension _MinecraftProfileCapeDomainMapper on client.MinecraftProfileCape {
  MinecraftProfileCape _toDomain() => MinecraftProfileCape(
    id: id,
    alias: alias,
    url: url,
    state: state._toDomain(),
  );
}

extension _MinecraftSkinVariantDomainMapper on client.MinecraftSkinVariant {
  MinecraftSkinVariant _toDomain() => switch (this) {
    client.MinecraftSkinVariant.classic => MinecraftSkinVariant.classic,
    client.MinecraftSkinVariant.slim => MinecraftSkinVariant.slim,
  };
}
