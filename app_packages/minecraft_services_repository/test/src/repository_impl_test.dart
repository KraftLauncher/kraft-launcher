import 'dart:typed_data' show Uint8List;

import 'package:checks/checks.dart';
import 'package:minecraft_services_client/minecraft_services_client.dart'
    as client;
import 'package:minecraft_services_repository/minecraft_services_repository.dart';
import 'package:result/result.dart';
import 'package:test/scaffolding.dart';

import 'fake_minecraft_services_api_client.dart';

void main() {
  late DefaultMinecraftServicesRepository repository;
  late FakeMinecraftServicesApiClient fakeMinecraftServicesApiClient;

  setUp(() {
    fakeMinecraftServicesApiClient = FakeMinecraftServicesApiClient();
    repository = DefaultMinecraftServicesRepository(
      apiClient: fakeMinecraftServicesApiClient,
    );
  });

  group('authenticateWithXbox', () {
    test('forwards the provided arguments to the API client', () async {
      const xstsToken = 'FAKE_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      const xstsUserHash = 'FAKE_1234567890ABCDEF1234567890ABCDEF';

      await repository.authenticateWithXbox(
        xstsToken: xstsToken,
        xstsUserHash: xstsUserHash,
      );

      final call =
          fakeMinecraftServicesApiClient.authenticateWithXboxCalls.first;

      check(call.xstsToken).equals(xstsToken);
      check(call.xstsUserHash).equals(xstsUserHash);
    });

    test(
      'maps the DTO from API client to domain $MinecraftLoginResponse on success',
      () async {
        const clientResponse = client.MinecraftLoginResponse(
          username: 'Steve',
          accessToken: 'access_token',
          expiresIn: 3600,
        );

        fakeMinecraftServicesApiClient.whenAuthenticateWithXbox = (call) async {
          return Result.success(httpResponseWithDefaults(body: clientResponse));
        };

        final response =
            (await repository.authenticateWithXboxWithDefaults()).valueOrThrow;

        check(response)
            .has((e) => e.accessToken, 'accessToken')
            .equals(clientResponse.accessToken);
        check(
          response,
        ).has((e) => e.expiresIn, 'expiresIn').equals(clientResponse.expiresIn);
        check(
          response,
        ).has((e) => e.username, 'username').equals(clientResponse.username);
      },
    );

    _domainFailureMappingTests(
      mockFailure: (failure) {
        fakeMinecraftServicesApiClient.whenAuthenticateWithXbox =
            (call) async => Result.failure(failure);
      },
      makeRequest: () async =>
          (await repository.authenticateWithXboxWithDefaults()).failureOrThrow,
    );

    test('sends request only once', () async {
      await repository.authenticateWithXboxWithDefaults();

      check(
        fakeMinecraftServicesApiClient.authenticateWithXboxCalls.length,
      ).equals(1);
    });
  });

  group('fetchProfile', () {
    test('forwards the provided arguments to the API client', () async {
      const accessToken = 'FAKE_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

      await repository.fetchProfile(accessToken: accessToken);

      final call = fakeMinecraftServicesApiClient.fetchProfileCalls.first;
      check(call.accessToken).equals(accessToken);
    });

    _minecraftProfileMappingTest(
      mockApiClient: (response) =>
          fakeMinecraftServicesApiClient.whenFetchProfile = (_) async =>
              response,
      makeRequest: () async => repository.fetchProfileDefaults(),
    );

    _domainFailureMappingTests(
      mockFailure: (failure) {
        fakeMinecraftServicesApiClient.whenFetchProfile = (call) async =>
            Result.failure(failure);
      },
      makeRequest: () async =>
          (await repository.fetchProfileDefaults()).failureOrThrow,
    );

    test('maps NOT_FOUND error to domain $AccountNotFoundFailure', () async {
      fakeMinecraftServicesApiClient.whenFetchProfile = (_) async {
        return Result.failure(
          client.HttpStatusFailure(
            response: httpResponseWithDefaults(
              body: const client.MinecraftErrorResponse(
                path: 'dummy',
                error: 'NOT_FOUND',
                errorMessage: 'dummy',
              ),
            ),
          ),
        );
      };
      final response = await repository.fetchProfileDefaults();

      check(response.failureOrNull).isA<AccountNotFoundFailure>();
    });

    test('sends request only once', () async {
      await repository.fetchProfileDefaults();

      check(fakeMinecraftServicesApiClient.fetchProfileCalls.length).equals(1);
    });
  });

  group('hasValidMinecraftJavaLicense', () {
    test('forwards the provided arguments to the API client', () async {
      const accessToken = 'FAKE_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

      await repository.hasValidMinecraftJavaLicense(accessToken: accessToken);

      final call = fakeMinecraftServicesApiClient.fetchEntitlementsCalls.first;
      check(call.accessToken).equals(accessToken);
    });

    _domainFailureMappingTests(
      mockFailure: (failure) {
        fakeMinecraftServicesApiClient.whenFetchEntitlements = (call) async =>
            Result.failure(failure);
      },
      makeRequest: () async =>
          (await repository.hasValidMinecraftJavaLicenseWithDefaults())
              .failureOrThrow,
    );

    for (final entitlementsItemNames in {
      ['product_minecraft', 'game_minecraft'],
      ['product_minecraft'],
      ['game_minecraft'],
      <String>[],
    }) {
      const requiredNames = {'product_minecraft', 'game_minecraft'};

      final ownsMinecraft = requiredNames.every(
        (name) => entitlementsItemNames.any((itemName) => itemName == name),
      );
      test(
        'returns $ownsMinecraft when entitlements ${ownsMinecraft ? 'contain' : 'do not contain'} both product_minecraft and game_minecraft',
        () async {
          fakeMinecraftServicesApiClient.whenFetchEntitlements = (_) async {
            return Result.success(
              httpResponseWithDefaults(
                body: client.MinecraftEntitlementsResponse(
                  items: entitlementsItemNames
                      .map(
                        (name) => client.MinecraftEntitlementItem(
                          name: name,
                          signature: 'dummy',
                        ),
                      )
                      .toList(),
                  signature: 'dummy',
                  keyId: 'dummy',
                ),
              ),
            );
          };

          final result =
              (await repository.hasValidMinecraftJavaLicenseWithDefaults())
                  .valueOrThrow;

          check(result).equals(ownsMinecraft);
        },
      );

      test('sends request only once', () async {
        await repository.hasValidMinecraftJavaLicenseWithDefaults();

        check(
          fakeMinecraftServicesApiClient.fetchEntitlementsCalls.length,
        ).equals(1);
      });
    }
  });

  group('uploadSkin', () {
    test('forwards access token argument to API client', () async {
      const accessToken = 'FAKE_e21231';

      await repository.uploadSkinWithDefaults(accessToken: accessToken);

      check(
        fakeMinecraftServicesApiClient.uploadSkinCalls.first.accessToken,
      ).equals(accessToken);
    });

    test('passes variant argument to API client mapped to DTO', () async {
      for (final variant in MinecraftSkinVariant.values) {
        await repository.uploadSkinWithDefaults(variant: variant);

        check(
          fakeMinecraftServicesApiClient.uploadSkinCalls.first.variant,
        ).equals(switch (variant) {
          MinecraftSkinVariant.classic => client.MinecraftSkinVariant.classic,
          MinecraftSkinVariant.slim => client.MinecraftSkinVariant.slim,
        });

        fakeMinecraftServicesApiClient.reset();
      }
    });

    test('uses image/png content type', () async {
      await repository.uploadSkinWithDefaults();

      check(
        fakeMinecraftServicesApiClient
            .uploadSkinCalls
            .first
            .skinFile
            .contentType,
      ).has((e) => e.mimeType, 'mimeType').equals('image/png');
    });

    test('passes skin bytes argument to API client', () async {
      final expectedBytes = [1, 2, 1, 0, 5];

      await repository.uploadSkinWithDefaults(
        skinBytes: Uint8List.fromList(expectedBytes),
      );

      final List<int> capturedBytes = await fakeMinecraftServicesApiClient
          .uploadSkinCalls
          .first
          .skinFile
          .finalize()
          .toBytes();

      check(capturedBytes).deepEquals(expectedBytes);
    });

    test('uses "file" for file field name', () async {
      // Not very important test; the API ignores the skin file field name.

      await repository.uploadSkinWithDefaults();

      check(
        fakeMinecraftServicesApiClient.uploadSkinCalls.first.skinFile.field,
      ).equals('file');
    });

    test('sends request only once', () async {
      await repository.uploadSkinWithDefaults();

      check(fakeMinecraftServicesApiClient.uploadSkinCalls.length).equals(1);
    });

    _domainFailureMappingTests(
      mockFailure: (failure) {
        fakeMinecraftServicesApiClient.whenUploadSkin = (call) async =>
            Result.failure(failure);
      },
      makeRequest: () async =>
          (await repository.uploadSkinWithDefaults()).failureOrThrow,
    );

    _minecraftProfileMappingTest(
      mockApiClient: (response) =>
          fakeMinecraftServicesApiClient.whenUploadSkin = (_) async => response,
      makeRequest: () async => repository.uploadSkinWithDefaults(),
    );

    test(
      'returns $InvalidSkinImageDataFailure when API rejects the skin image',
      () async {
        fakeMinecraftServicesApiClient.whenUploadSkin = (_) async {
          return Result.failure(
            client.HttpStatusFailure(
              response: httpResponseWithDefaults(
                statusCode: client.HttpStatusCodes.badRequest,
                body: const client.MinecraftErrorResponse(
                  path: 'dummy',
                  error: 'dummy',
                  errorMessage: 'Could not validate image data.',
                ),
              ),
            ),
          );
        };
        final response = await repository.uploadSkinWithDefaults();

        check(response.failureOrNull).isA<InvalidSkinImageDataFailure>();
      },
    );
  });
}

void _minecraftProfileMappingTest({
  required void Function(
    client.MinecraftApiResult<client.MinecraftProfileResponse> response,
  )
  mockApiClient,
  required Future<MinecraftServicesResult<MinecraftProfileResponse>> Function()
  makeRequest,
}) {
  test(
    'maps the DTO from API client to domain $MinecraftProfileResponse on success',
    () async {
      const clientResponse = client.MinecraftProfileResponse(
        id: 'USER_ID',
        name: 'STEVE',
        skins: [
          client.MinecraftProfileSkin(
            id: 'example_id',
            url: 'example_url',
            textureKey: 'example_textureKey',
            variant: client.MinecraftSkinVariant.classic,
            state: client.MinecraftCosmeticState.active,
          ),
          client.MinecraftProfileSkin(
            id: 'example_id_2',
            url: 'example_url_2',
            textureKey: 'example_textureKey_2',
            variant: client.MinecraftSkinVariant.slim,
            state: client.MinecraftCosmeticState.inactive,
          ),
        ],
        capes: [
          client.MinecraftProfileCape(
            id: 'example_id',
            url: 'example_url',
            state: client.MinecraftCosmeticState.inactive,
            alias: 'EXAMPLE_ALIAS',
          ),
        ],
      );

      mockApiClient(
        Result.success(httpResponseWithDefaults(body: clientResponse)),
      );

      final response = (await makeRequest()).valueOrThrow;

      check(response).has((e) => e.id, 'id').equals(clientResponse.id);
      check(response).has((e) => e.name, 'name').equals(clientResponse.name);

      MinecraftCosmeticState mapState(client.MinecraftCosmeticState state) =>
          switch (state) {
            client.MinecraftCosmeticState.active =>
              MinecraftCosmeticState.active,
            client.MinecraftCosmeticState.inactive =>
              MinecraftCosmeticState.inactive,
          };
      check(response)
          .has((e) => e.skins, 'skins')
          .deepEquals(
            clientResponse.skins
                .map(
                  (e) => MinecraftProfileSkin(
                    id: e.id,
                    url: e.url,
                    textureKey: e.textureKey,
                    variant: switch (e.variant) {
                      client.MinecraftSkinVariant.classic =>
                        MinecraftSkinVariant.classic,
                      client.MinecraftSkinVariant.slim =>
                        MinecraftSkinVariant.slim,
                    },
                    state: mapState(e.state),
                  ),
                )
                .toList(),
          );
      check(response)
          .has((e) => e.capes, 'capes')
          .deepEquals(
            clientResponse.capes
                .map(
                  (e) => MinecraftProfileCape(
                    id: e.id,
                    state: mapState(e.state),
                    url: e.url,
                    alias: e.alias,
                  ),
                )
                .toList(),
          );
    },
  );
}

void _domainFailureMappingTests({
  required void Function(
    client.ApiFailure<client.MinecraftErrorResponse> failure,
  )
  mockFailure,
  required Future<MinecraftServicesFailure> Function() makeRequest,
}) {
  test(
    'maps API client ${client.ConnectionFailure} to domain $ConnectionFailure',
    () async {
      const message = 'Example connection failure';
      mockFailure(const client.ConnectionFailure(message));

      final failure = await makeRequest();

      check(failure)
          .isA<ConnectionFailure>()
          .has((e) => e.message, 'message')
          .endsWith(message);
    },
  );

  test(
    'maps API client ${client.UnexpectedFailure} to domain $UnexpectedFailure',
    () async {
      const message = 'Example unknown failure';
      mockFailure(const client.UnexpectedFailure(message));

      final failure = await makeRequest();

      check(failure)
          .isA<UnexpectedFailure>()
          .has((e) => e.message, 'message')
          .endsWith(message);
    },
  );

  test(
    'maps API client ${client.JsonDecodingFailure} to domain $InvalidDataFormatFailure',
    () async {
      const reason = 'Example reason';
      const responseBody = '{}';
      mockFailure(const client.JsonDecodingFailure(responseBody, reason));

      final failure = await makeRequest();

      check(failure)
          .isA<InvalidDataFormatFailure>()
          .has((e) => e.message, 'message')
          .equals('Invalid data format: $reason\nResponse body: $responseBody');
    },
  );

  test(
    'maps API client ${client.JsonDeserializationFailure} to domain $UnexpectedDataStructureFailure',
    () async {
      const reason = 'Example reason';
      const data = <String, Object?>{};
      mockFailure(client.JsonDeserializationFailure(data, reason));

      final failure = await makeRequest();

      check(failure)
          .isA<UnexpectedDataStructureFailure>()
          .has((e) => e.message, 'message')
          .equals('Unexpected data structure: $reason\nData: $data');
    },
  );

  group('HTTP error response mapping', () {
    void mockHttpStatusFailure({
      required int statusCode,
      client.MinecraftErrorResponse? response,
      Map<String, String> headers = const {},
    }) {
      mockFailure(
        client.HttpStatusFailure(
          response: httpResponseWithDefaults(
            body:
                response ??
                const client.MinecraftErrorResponse(
                  path: 'dummy',
                  error: 'dummy',
                  errorMessage: 'dummy',
                ),
            statusCode: statusCode,
            headers: headers,
          ),
        ),
      );
    }

    test(
      'maps API client ${client.HttpStatusFailure} with 429 to domain $TooManyRequestsFailure',
      () async {
        mockHttpStatusFailure(
          statusCode: client.HttpStatusCodes.tooManyRequests,
        );

        final failure = await makeRequest();

        check(failure).isA<TooManyRequestsFailure>();
      },
    );

    test(
      'maps API client ${client.HttpStatusFailure} with 401 to domain $UnauthorizedAccessFailure',
      () async {
        mockHttpStatusFailure(statusCode: client.HttpStatusCodes.unauthorized);

        final failure = await makeRequest();

        check(failure).isA<UnauthorizedAccessFailure>();
      },
    );

    test(
      'maps API client ${client.HttpStatusFailure} with 503 to domain $ServiceUnavailableFailure',
      () async {
        const retryAfterInSeconds = 60;
        mockHttpStatusFailure(
          statusCode: client.HttpStatusCodes.serviceUnavailable,
          headers: {client.HttpHeaderNames.retryAfter: '$retryAfterInSeconds'},
        );

        final failure = await makeRequest();

        check(failure)
            .isA<ServiceUnavailableFailure>()
            .has((e) => e.retryAfterInSeconds, 'retryAfterInSeconds')
            .equals(retryAfterInSeconds);
      },
    );

    test(
      'maps API client ${client.HttpStatusFailure} with 500 to domain $InternalServerFailure',
      () async {
        const statusCode = client.HttpStatusCodes.internalServerError;
        mockHttpStatusFailure(statusCode: statusCode);

        final failure = await makeRequest();

        check(failure).isA<InternalServerFailure>();
      },
    );

    test(
      'maps API client ${client.HttpStatusFailure} with unhandled status code to domain $UnhandledServerResponseFailure',
      () async {
        mockHttpStatusFailure(
          // An example of unhandled case
          statusCode: client.HttpStatusCodes.conflict,
        );

        final failure = await makeRequest();

        check(failure).isA<UnhandledServerResponseFailure>();
      },
    );
  });
}

extension _MinecraftServicesRepositoryWithDefaults
    on MinecraftServicesRepository {
  Future<MinecraftServicesResult<MinecraftLoginResponse>>
  authenticateWithXboxWithDefaults({
    String xstsToken = 'dummy',
    String xstsUserHash = 'dummy',
  }) => authenticateWithXbox(xstsToken: xstsToken, xstsUserHash: xstsUserHash);

  Future<MinecraftServicesResult<MinecraftProfileResponse>>
  fetchProfileDefaults({String accessToken = 'dummy'}) =>
      fetchProfile(accessToken: accessToken);

  Future<MinecraftServicesResult<bool>>
  hasValidMinecraftJavaLicenseWithDefaults({String? accessToken}) =>
      hasValidMinecraftJavaLicense(accessToken: accessToken ?? '');

  Future<MinecraftServicesResult<MinecraftProfileResponse>>
  uploadSkinWithDefaults({
    String? accessToken,
    Uint8List? skinBytes,
    MinecraftSkinVariant? variant,
  }) => uploadSkin(
    accessToken: accessToken ?? 'dummy',
    skinBytes: skinBytes ?? Uint8List.fromList([]),
    variant: variant ?? MinecraftSkinVariant.slim,
  );
}
