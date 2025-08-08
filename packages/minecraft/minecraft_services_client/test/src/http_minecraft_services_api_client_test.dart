import 'package:json_utils/json_utils.dart' show JsonMap;
import 'package:minecraft_services_client/minecraft_services_client.dart';
import 'package:minecraft_services_client/src/models/minecraft_entitlements_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_error_response.dart';
import 'package:minecraft_services_client/src/models/minecraft_login_response.dart';
import 'package:minecraft_services_client/src/models/profile/minecraft_profile_response.dart';
import 'package:minecraft_services_client/src/models/profile/skin/enums/minecraft_cosmetic_state.dart';
import 'package:minecraft_services_client/src/models/profile/skin/minecraft_profile_cape.dart';
import 'package:minecraft_services_client/src/models/profile/skin/minecraft_profile_skin.dart';
import 'package:result/result.dart';
import 'package:safe_http/safe_http.dart';

import 'package:safe_http/test.dart';
import 'package:test/test.dart';

const _host = MinecraftServicesApiClient.baseUrlHost;

void main() {
  late FakeApiClient fakeJsonApiClient;
  late MinecraftServicesApiClient client;

  setUp(() {
    fakeJsonApiClient = FakeApiClient();
    client = HttpMinecraftServicesApiClient(apiClient: fakeJsonApiClient);

    fakeJsonApiClient.whenRequestJson = <S, C>(call) async {
      return Result.failure(const ConnectionFailure('any'));
    };
  });

  group('authenticateWithXbox', () {
    MinecraftApiResultFuture<MinecraftLoginResponse> authenticateWithXbox({
      String? xstsToken,
      String? xstsUserHash,
    }) => client.authenticateWithXbox(
      xstsToken: xstsToken ?? 'any',
      xstsUserHash: xstsUserHash ?? 'any',
    );

    test('passes expected URL to $ApiClient', () async {
      await authenticateWithXbox();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;

      expect(call?.url, Uri.https(_host, '/authentication/login_with_xbox'));
    });

    test('builds and passes expected JSON body to $ApiClient', () async {
      const xstsToken = 'example_xsts_token';
      const xstsUserHash = 'example_xsts_user_hash';

      await authenticateWithXbox(
        xstsToken: xstsToken,
        xstsUserHash: xstsUserHash,
      );

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;

      expect(call?.body, {
        'identityToken': 'XBL3.0 x=$xstsUserHash;$xstsToken',
      });
    });

    test('passes isJsonBody = true to $ApiClient', () async {
      await authenticateWithXbox();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.isJsonBody, true);
    });

    _testClientFailureResponseParse(
      makeRequest: () => authenticateWithXbox(),
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test(
      'parses successful JSON response into $MinecraftLoginResponse',
      () async {
        const expectedResponse = MinecraftLoginResponse(
          expiresIn: 3600,
          accessToken: 'Access token',
          username: 'Steve',
        );
        final JsonMap json = {
          'expires_in': expectedResponse.expiresIn,
          'access_token': expectedResponse.accessToken,
          'username': expectedResponse.username,
        };

        await fakeJsonApiClient.stubJsonSuccessAndRun(
          json: json,
          expectedDecodedBody: expectedResponse,
          assertion: (result) => expect(result, expectedResponse),
          makeRequest: authenticateWithXbox,
        );
      },
    );

    _testReturnValue(
      makeRequest: authenticateWithXbox,
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test('sends request once using HTTP POST', () async {
      await authenticateWithXbox();
      fakeJsonApiClient.expectSingleRequest(
        isRequestJsonMethod: true,
        method: HttpMethod.post,
      );
    });
  });

  group('fetchEntitlements', () {
    MinecraftApiResultFuture<MinecraftEntitlementsResponse> fetchEntitlements({
      String? accessToken,
    }) => client.fetchEntitlements(accessToken: accessToken ?? 'any');

    test('passes expected URL to $ApiClient', () async {
      await fetchEntitlements();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.url, Uri.https(_host, 'entitlements/mcstore'));
    });

    test('passes headers with Authorization to $ApiClient', () async {
      const expectedAccessToken = 'eMinecraftAccessToken';

      await fetchEntitlements(accessToken: expectedAccessToken);

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.headers, {'Authorization': 'Bearer $expectedAccessToken'});
    });

    _testClientFailureResponseParse(
      makeRequest: () => fetchEntitlements(),
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test(
      'parses successful JSON response into $MinecraftEntitlementsResponse',
      () async {
        const expectedResponse = MinecraftEntitlementsResponse(
          items: [
            MinecraftEntitlementItem(
              name: 'product_minecraft',
              signature: 'jwt sig',
            ),
            MinecraftEntitlementItem(
              name: 'game_minecraft',
              signature: 'jwt sig',
            ),
          ],
          keyId: '1',
          signature: 'jwt sig',
        );
        final JsonMap json = {
          'keyId': expectedResponse.keyId,
          'signature': expectedResponse.signature,
          'items': expectedResponse.items
              .map((e) => {'name': e.name, 'signature': e.signature})
              .toList(),
        };

        await fakeJsonApiClient.stubJsonSuccessAndRun(
          json: json,
          expectedDecodedBody: expectedResponse,
          assertion: (result) => expect(result, expectedResponse),
          makeRequest: fetchEntitlements,
        );
      },
    );

    _testReturnValue(
      makeRequest: fetchEntitlements,
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test('sends request once using HTTP GET', () async {
      await fetchEntitlements();
      fakeJsonApiClient.expectSingleRequest(
        isRequestJsonMethod: true,
        method: HttpMethod.get,
      );
    });
  });

  group('fetchProfile', () {
    MinecraftApiResultFuture<MinecraftProfileResponse> fetchProfile({
      String? accessToken,
    }) => client.fetchProfile(accessToken: accessToken ?? 'any');

    test('passes expected URL to $ApiClient', () async {
      await fetchProfile();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.url, Uri.https(_host, 'minecraft/profile'));
    });

    test('passes headers with Authorization to $ApiClient', () async {
      const expectedAccessToken = 'e2MinecraftAccessToken';

      await fetchProfile(accessToken: expectedAccessToken);

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.headers, {'Authorization': 'Bearer $expectedAccessToken'});
    });

    _testClientFailureResponseParse(
      makeRequest: () => fetchProfile(),
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test(
      'parses successful JSON response into $MinecraftProfileResponse',
      () async {
        const expectedResponse = _exampleMinecraftProfileResponse;
        final JsonMap json = expectedResponse._toJson();

        await fakeJsonApiClient.stubJsonSuccessAndRun(
          json: json,
          expectedDecodedBody: expectedResponse,
          assertion: (result) => expect(result, expectedResponse),
          makeRequest: fetchProfile,
        );
      },
    );

    _testReturnValue(
      makeRequest: fetchProfile,
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test('sends request once using HTTP GET', () async {
      await fetchProfile();
      fakeJsonApiClient.expectSingleRequest(
        isRequestJsonMethod: true,
        method: HttpMethod.get,
      );
    });
  });

  group('uploadSkin', () {
    MinecraftApiResultFuture<MinecraftProfileResponse> uploadSkin({
      String? accessToken,
      MultipartFile? skinFile,
      MinecraftSkinVariant? variant,
    }) => client.uploadSkin(
      accessToken: accessToken ?? 'any',
      skinFile: skinFile ?? MultipartFile.fromBytes('any', []),
      variant: variant ?? MinecraftSkinVariant.slim,
    );

    test('passes expected URL to $ApiClient', () async {
      await uploadSkin();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;

      expect(call?.url, Uri.https(_host, 'minecraft/profile/skins'));
    });

    test('passes headers with Authorization to $ApiClient', () async {
      const expectedAccessToken = 'eMinecraftAccessToken';

      await uploadSkin(accessToken: expectedAccessToken);

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.headers, {'Authorization': 'Bearer $expectedAccessToken'});
    });

    test('passes isJsonBody = false to $ApiClient', () async {
      await uploadSkin();

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      expect(call?.isJsonBody, false);
    });

    test('builds and passes expected $MultipartBody to $ApiClient', () async {
      const expectedSkinVariant = MinecraftSkinVariant.classic;
      final expectedSkinFile = MultipartFile.fromBytes('file', []);

      await uploadSkin(
        variant: expectedSkinVariant,
        skinFile: expectedSkinFile,
      );

      final call = fakeJsonApiClient.requestJsonCalls.firstOrNull;
      final body = call?.body;

      expect(body, isA<MultipartBody>());

      final multipartBody = body! as MultipartBody;

      expect(multipartBody.fields, {'variant': expectedSkinVariant.toJson()});
      expect(multipartBody.files.firstOrNull, same(expectedSkinFile));
      expect(
        multipartBody.files.length,
        1,
        reason: 'Should avoid passing multiple files.',
      );
    });

    _testClientFailureResponseParse(
      makeRequest: () => uploadSkin(),
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test(
      'parses successful JSON response into $MinecraftProfileResponse',
      () async {
        const expectedResponse = _exampleMinecraftProfileResponse;
        final JsonMap json = expectedResponse._toJson();

        await fakeJsonApiClient.stubJsonSuccessAndRun(
          json: json,
          expectedDecodedBody: expectedResponse,
          assertion: (result) => expect(result, expectedResponse),
          makeRequest: uploadSkin,
        );
      },
    );

    _testReturnValue(
      makeRequest: uploadSkin,
      getFakeJsonApiClient: () => fakeJsonApiClient,
    );

    test('sends request once using HTTP POST', () async {
      await uploadSkin();
      fakeJsonApiClient.expectSingleRequest(
        isRequestJsonMethod: true,
        method: HttpMethod.post,
      );
    });
  });
}

void _testClientFailureResponseParse({
  required Future<void> Function() makeRequest,
  required FakeApiClient Function() getFakeJsonApiClient,
}) {
  test(
    'parses client error JSON response into $MinecraftErrorResponse',
    () async {
      final fakeJsonApiClient = getFakeJsonApiClient();

      const expectedResponse = MinecraftErrorResponse(
        path: '/example',
        error: 'UNAUTHORIZED',
        errorMessage: 'Unauthorized',
      );
      final JsonMap json = {
        'path': expectedResponse.path,
        'error': expectedResponse.error,
        'errorMessage': expectedResponse.errorMessage,
      };

      await fakeJsonApiClient.stubJsonFailureAndRun(
        json: json,
        expectedDecodedBody: expectedResponse,
        assertion: (result) => expect(result, expectedResponse),
        makeRequest: makeRequest,
      );
    },
  );
}

void _testReturnValue<R>({
  required Future<MinecraftApiResult<R>> Function() makeRequest,
  required FakeApiClient Function() getFakeJsonApiClient,
}) {
  test('returns $Result from $ApiClient', () async {
    final fakeJsonApiClient = getFakeJsonApiClient();

    final expectedResult = MinecraftApiResult<R>.failure(
      // Example dummy result.
      const UnknownFailure('An unknown error'),
    );

    fakeJsonApiClient.whenRequestJson = <S, C>(call) async {
      return expectedResult as JsonApiResult<S, C>;
    };

    final result = await makeRequest();

    expect(result, same(expectedResult));
  });
}

extension on MinecraftProfileResponse {
  JsonMap _toJson() => {
    'id': id,
    'name': name,
    'skins': skins
        .map(
          (skin) => {
            'id': skin.id,
            'state': skin.state.name.toUpperCase(),
            'variant': skin.variant.name.toUpperCase(),
            'textureKey': skin.textureKey,
            'url': skin.url,
          },
        )
        .toList(),
    'capes': capes
        .map(
          (cape) => {
            'id': cape.id,
            'state': cape.state.name.toUpperCase(),
            'alias': cape.alias,
            'url': cape.url,
          },
        )
        .toList(),
  };
}

const _exampleMinecraftProfileResponse = MinecraftProfileResponse(
  id: 'MINECRAFT_ID_41321321',
  capes: [
    MinecraftProfileCape(
      id: '1ed5269a-076e-4a3c-834a-2837d5b578f2',
      state: MinecraftCosmeticState.inactive,
      url:
          'http://textures.minecraft.net/texture/28de4a81688ad18b49e735a273e486c18f1e3966956123ccb574034c06f5d336',
      alias: 'Pan',
    ),
    MinecraftProfileCape(
      id: '4af20372-79e0-4e1f-80f8-6bd8e3135995',
      state: MinecraftCosmeticState.active,
      url:
          'http://textures.minecraft.net/texture/2340c0e03dd24a11b15a8b33c2a7e1e32abb2051b2481d0ba7defd635ca7a933',
      alias: 'Migrator',
    ),
    MinecraftProfileCape(
      id: 'a9d4f2e0-6109-43f7-97aa-84250ce3c1dd',
      state: MinecraftCosmeticState.inactive,
      url:
          'http://textures.minecraft.net/texture/5ec930cdd2629c8771655c60eebeb887b4b6559b0e6d3bc71c40c96347fa03f0',
      alias: 'Common',
    ),
  ],
  skins: [
    MinecraftProfileSkin(
      id: '6baa3a08-0e6d-4067-b056-52abb5b2e913',
      state: MinecraftCosmeticState.active,
      url:
          'http://textures.minecraft.net/texture/b56acf72e21992071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
      textureKey:
          'b56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
      variant: MinecraftSkinVariant.classic,
    ),
    MinecraftProfileSkin(
      id: '6baa3a08-0e6d-4067-b056-52abb5b2e913',
      state: MinecraftCosmeticState.inactive,
      url:
          'http://textures.minecraft.net/texture/b36acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
      textureKey:
          'b56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
      variant: MinecraftSkinVariant.slim,
    ),
  ],
  name: 'Steve',
);
