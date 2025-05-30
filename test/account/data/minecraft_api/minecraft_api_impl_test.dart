import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart'
    as microsoft_api
    show XboxLiveAuthTokenResponse;
import 'package:kraft_launcher/account/data/minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api_exceptions.dart';
import 'package:kraft_launcher/account/data/minecraft_api/minecraft_api_impl.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../common/helpers/dio_utils.dart';
import '../../../common/helpers/temp_file_utils.dart';

void main() {
  late MinecraftApi minecraftApi;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    minecraftApi = MinecraftApiImpl(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(Uri.https('dummy-instance.com'));
  });

  microsoft_api.XboxLiveAuthTokenResponse xboxLiveTokenResponse({
    String xboxToken = '',
    String userHash = '',
  }) => microsoft_api.XboxLiveAuthTokenResponse(
    xboxToken: xboxToken,
    userHash: userHash,
  );

  group('loginToMinecraftWithXbox', () {
    test(
      'uses expected request URI, headers, and body with xbox token and hash',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {'username': '', 'access_token': '', 'expires_in': -1},
        );

        final xboxLiveToken = xboxLiveTokenResponse(
          userHash: 'Example user hash',
          xboxToken: 'Example Xbox token',
        );
        await minecraftApi.loginToMinecraftWithXbox(xboxLiveToken);
        final captured =
            mockDio.capturePostUriArguments<JsonObject, JsonObject>();

        expect(captured.options?.headers, {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
        expect(
          captured.uri,
          Uri.https(
            'api.minecraftservices.com',
            '/authentication/login_with_xbox',
          ),
        );
        expect(captured.requestData, {
          'identityToken':
              'XBL3.0 x=${xboxLiveToken.userHash};${xboxLiveToken.xboxToken}',
        });
      },
    );
    test('returns parsed $MinecraftLoginResponse on success', () async {
      const expiresIn = 3600;
      const accessToken = 'Example Access Token';
      const username = 'Example Username';
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {
          'access_token': accessToken,
          'username': username,
          'expires_in': expiresIn,
        },
      );

      final response = await minecraftApi.loginToMinecraftWithXbox(
        xboxLiveTokenResponse(),
      );

      expect(response.accessToken, accessToken);
      expect(response.username, username);
      expect(response.expiresIn, expiresIn);
    });
    _tooManyRequestsTest(
      () => mockDio,
      () => minecraftApi.loginToMinecraftWithXbox(xboxLiveTokenResponse()),
      isPostRequest: true,
    );
    _unknownErrorTests(
      () => mockDio,
      () => minecraftApi.loginToMinecraftWithXbox(xboxLiveTokenResponse()),
      isPostRequest: true,
    );
    _unauthorizedTest(
      () => mockDio,
      () => minecraftApi.loginToMinecraftWithXbox(xboxLiveTokenResponse()),
      isPostRequest: true,
    );
  });
  const fakeMcAccessToken = 'eMinecraftAccessToken';

  group('fetchMinecraftProfile', () {
    test('uses expected request URI, passes Authorization header', () async {
      mockDio.mockGetUriSuccess<JsonObject>(
        responseData: {'id': '', 'name': '', 'skins': [], 'capes': []},
      );

      await minecraftApi.fetchMinecraftProfile(fakeMcAccessToken);
      final captured = mockDio.captureGetUriArguments<JsonObject, JsonObject>();

      expect(captured.options?.headers, {
        'Authorization': 'Bearer $fakeMcAccessToken',
      });
      expect(
        captured.uri,
        Uri.https('api.minecraftservices.com', '/minecraft/profile'),
      );
    });

    test('returns parsed $MinecraftProfileResponse on success', () async {
      const id = 'Minecraft ID';
      const name = 'Steve';
      const skins = <JsonObject>[
        {
          'id': '6baa3a08-0e6d-4067-b056-52abb5b2e913',
          'state': 'ACTIVE',
          'url':
              'http://textures.minecraft.net/texture/b56acf72e21992071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
          'textureKey':
              'b56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
          'variant': 'CLASSIC',
        },
        {
          'id': '6baa3a08-0e6d-4067-b056-52abb5b2e913',
          'state': 'INACTIVE',
          'url':
              'http://textures.minecraft.net/texture/b36acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
          'textureKey':
              'b56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
          'variant': 'CLASSIC',
        },
      ];
      const capes = <JsonObject>[
        {
          'id': '1ed5269a-076e-4a3c-834a-2837d5b578f2',
          'state': 'INACTIVE',
          'url':
              'http://textures.minecraft.net/texture/28de4a81688ad18b49e735a273e486c18f1e3966956123ccb574034c06f5d336',
          'alias': 'Pan',
        },
        {
          'id': '4af20372-79e0-4e1f-80f8-6bd8e3135995',
          'state': 'ACTIVE',
          'url':
              'http://textures.minecraft.net/texture/2340c0e03dd24a11b15a8b33c2a7e1e32abb2051b2481d0ba7defd635ca7a933',
          'alias': 'Migrator',
        },
        {
          'id': 'a9d4f2e0-6109-43f7-97aa-84250ce3c1dd',
          'state': 'INACTIVE',
          'url':
              'http://textures.minecraft.net/texture/5ec930cdd2629c8771655c60eebeb887b4b6559b0e6d3bc71c40c96347fa03f0',
          'alias': 'Common',
        },
      ];
      mockDio.mockGetUriSuccess<JsonObject>(
        responseData: {'id': id, 'name': name, 'skins': skins, 'capes': capes},
      );

      final response = await minecraftApi.fetchMinecraftProfile(
        fakeMcAccessToken,
      );

      expect(response.id, id);
      expect(response.name, name);
      expect(
        response.skins,
        skins.map((skin) => MinecraftProfileSkin.fromJson(skin)),
      );
      expect(
        response.capes,
        capes.map((cape) => MinecraftProfileCape.fromJson(cape)),
      );
    });
    _tooManyRequestsTest(
      () => mockDio,
      () => minecraftApi.fetchMinecraftProfile(fakeMcAccessToken),
      isPostRequest: false,
    );
    _unknownErrorTests(
      () => mockDio,
      () => minecraftApi.fetchMinecraftProfile(fakeMcAccessToken),
      isPostRequest: false,
    );
    _unauthorizedTest(
      () => mockDio,
      () => minecraftApi.fetchMinecraftProfile(fakeMcAccessToken),
      isPostRequest: false,
    );

    test(
      'throws $AccountNotFoundMinecraftApiException when the API indicates the account does not exist',
      () async {
        mockDio.mockGetUriFailure<JsonObject>(
          responseData: {'error': 'NOT_FOUND'},
        );

        await expectLater(
          minecraftApi.fetchMinecraftProfile(''),
          throwsA(isA<AccountNotFoundMinecraftApiException>()),
        );
      },
    );
  });
  group('checkMinecraftJavaOwnership', () {
    test('uses expected request URI, passes Authorization header', () async {
      mockDio.mockGetUriSuccess<JsonObject>(responseData: {'items': []});

      await minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken);
      final captured = mockDio.captureGetUriArguments<JsonObject, JsonObject>();

      expect(captured.options?.headers, {
        'Authorization': 'Bearer $fakeMcAccessToken',
      });
      expect(
        captured.uri,
        Uri.https('api.minecraftservices.com', '/entitlements/mcstore'),
      );
    });
    test('returns false when minecraft Java is not owned', () async {
      mockDio.mockGetUriSuccess<JsonObject>(responseData: {'items': []});

      expect(
        await minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken),
        false,
      );
    });

    test('returns true when minecraft Java is owned', () async {
      mockDio.mockGetUriSuccess<JsonObject>(
        responseData: {
          'items': [
            {'name': 'game_minecraft'},
          ],
        },
      );

      expect(
        await minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken),
        true,
      );
    });

    _tooManyRequestsTest(
      () => mockDio,
      () => minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken),
      isPostRequest: false,
    );
    _unknownErrorTests(
      () => mockDio,
      () => minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken),
      isPostRequest: false,
    );
    _unauthorizedTest(
      () => mockDio,
      () => minecraftApi.checkMinecraftJavaOwnership(fakeMcAccessToken),
      isPostRequest: false,
    );
  });
  group('uploadSkin', () {
    late File skinFile;
    late Directory tempTestDir;

    setUp(() {
      // TODO: Avoid IO operations in unit tests, track all usages of createTempTestDir and createFileInsideDir. Use file package instead
      tempTestDir = createTempTestDir();
      skinFile = createFileInsideDir(
        tempTestDir,
        fileName: 'minecraft-raw-skin.png',
      );
    });

    tearDown(() {
      tempTestDir.deleteSync(recursive: true);
    });

    test(
      'uses expected request URI, passes Authorization header and body',
      () async {
        mockDio.mockPostUriSuccess<JsonObject>(
          responseData: {'id': '', 'name': '', 'skins': [], 'capes': []},
        );

        const skinFileContent = 'Raw Skin Image content';
        skinFile.writeAsStringSync(skinFileContent);
        const skinVariant = MinecraftApiSkinVariant.classic;
        await minecraftApi.uploadSkin(
          skinFile,
          skinVariant: skinVariant,
          minecraftAccessToken: fakeMcAccessToken,
        );
        final captured =
            mockDio.capturePostUriArguments<FormData, JsonObject>();

        expect(captured.options?.headers, {
          'Authorization': 'Bearer $fakeMcAccessToken',
        });
        expect(
          captured.uri,
          Uri.https('api.minecraftservices.com', '/minecraft/profile/skins'),
        );
        expect(
          captured.requestData.fields
              .where((field) => field.key == 'variant')
              .firstOrNull
              ?.value
              .toLowerCase(),
          skinVariant.name.toLowerCase(),
        );
        final capturedSkinFile =
            captured.requestData.files
                .where((file) => file.key == 'file')
                .firstOrNull
                ?.value;
        expect(capturedSkinFile, isNotNull);
        expect(capturedSkinFile?.filename, p.basename(skinFile.path));
        expect(capturedSkinFile?.length, skinFile.lengthSync());
        expect(
          await capturedSkinFile?.finalize().first,
          skinFile.readAsBytesSync(),
        );
      },
    );

    test('returns parsed $MinecraftProfileResponse on success', () async {
      const id = 'Minecraft ID';
      const name = 'Steve';
      final skins = <JsonObject>[
        {
          'id': '432',
          'state': MinecraftCosmeticState.inactive.name.toUpperCase(),
          'url': 'https://',
          'textureKey': '123',
          'variant': MinecraftSkinVariant.classic.name.toUpperCase(),
        },
      ];
      const capes = <MinecraftProfileCape>[];
      mockDio.mockPostUriSuccess<JsonObject>(
        responseData: {'id': id, 'name': name, 'skins': skins, 'capes': capes},
      );

      final response = await minecraftApi.uploadSkin(
        skinFile,
        skinVariant: MinecraftApiSkinVariant.slim,
        minecraftAccessToken: fakeMcAccessToken,
      );

      expect(response.id, id);
      expect(response.name, name);
      expect(response.skins.length, skins.length);
      expect(response.capes.length, capes.length);
    });

    _tooManyRequestsTest(
      () => mockDio,
      () => minecraftApi.uploadSkin(
        skinFile,
        skinVariant: MinecraftApiSkinVariant.slim,
        minecraftAccessToken: fakeMcAccessToken,
      ),
      isPostRequest: true,
    );
    _unknownErrorTests(
      () => mockDio,
      () => minecraftApi.uploadSkin(
        skinFile,
        skinVariant: MinecraftApiSkinVariant.classic,
        minecraftAccessToken: fakeMcAccessToken,
      ),
      isPostRequest: true,
    );
    _unauthorizedTest(
      () => mockDio,
      () => minecraftApi.uploadSkin(
        skinFile,
        skinVariant: MinecraftApiSkinVariant.slim,
        minecraftAccessToken: fakeMcAccessToken,
      ),
      isPostRequest: true,
    );

    test(
      'throws $InvalidSkinImageDataMinecraftApiException when uploading invalid Minecraft skin image',
      () async {
        mockDio.mockPostUriFailure<JsonObject>(
          statusCode: HttpStatus.badRequest,
          responseData: {
            'path': '/minecraft/profile/skins',
            'errorMessage': 'Could not validate image data.',
          },
        );

        await expectLater(
          minecraftApi.uploadSkin(
            skinFile,
            skinVariant: MinecraftApiSkinVariant.slim,
            minecraftAccessToken: '',
          ),
          throwsA(isA<InvalidSkinImageDataMinecraftApiException>()),
        );
      },
    );
  });
}

void _tooManyRequestsTest(
  MockDio Function() mockDio,
  Future<void> Function() call, {
  required bool isPostRequest,
}) {
  test(
    'throws $TooManyRequestsMinecraftApiException on HTTP ${HttpStatus.tooManyRequests}',
    () async {
      if (isPostRequest) {
        mockDio().mockPostUriFailure<JsonObject>(
          statusCode: HttpStatus.tooManyRequests,
          responseData: {},
        );
      } else {
        mockDio().mockGetUriFailure<JsonObject>(
          responseData: {},
          statusCode: HttpStatus.tooManyRequests,
        );
      }

      await expectLater(
        call,
        throwsA(isA<TooManyRequestsMinecraftApiException>()),
      );
    },
  );
}

void _unknownErrorTests(
  MockDio Function() mockDio,
  Future<void> Function() call, {
  required bool isPostRequest,
}) {
  test(
    'throws $UnknownMinecraftApiException for unhandled or unknown errors with code and description when provided',
    () async {
      const errorCode = 'unknown_error_code';
      const errorMessage = 'The unknown error message';
      if (isPostRequest) {
        mockDio().mockPostUriFailure<JsonObject>(
          responseData: {'error': errorCode, 'errorMessage': errorMessage},
        );
      } else {
        mockDio().mockGetUriFailure<JsonObject>(
          responseData: {'error': errorCode, 'errorMessage': errorMessage},
        );
      }

      await expectLater(
        call,
        throwsA(
          isA<UnknownMinecraftApiException>()
              .having((e) => e.message, 'errorCode', contains(errorCode))
              .having((e) => e.message, 'errorMessage', contains(errorMessage)),
        ),
      );
    },
  );

  test(
    'throws $UnknownMinecraftApiException for unhandled or unknown errors without code and description when not provided',
    () async {
      if (isPostRequest) {
        mockDio().mockPostUriFailure<JsonObject>(responseData: {});
      } else {
        mockDio().mockGetUriFailure<JsonObject>(responseData: {});
      }

      await expectLater(call, throwsA(isA<UnknownMinecraftApiException>()));
    },
  );

  test(
    'throws $UnknownMinecraftApiException when catching $Exception',
    () async {
      final exception = Exception('Example exception');
      if (isPostRequest) {
        mockDio().mockPostUriFailure<JsonObject>(
          responseData: null,
          customException: exception,
        );
      } else {
        mockDio().mockGetUriFailure<JsonObject>(
          responseData: null,
          customException: exception,
        );
      }

      await expectLater(
        call,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            equals(exception.toString()),
          ),
        ),
      );
    },
  );
}

void _unauthorizedTest(
  MockDio Function() mockDio,
  Future<void> Function() call, {
  required bool isPostRequest,
}) {
  test(
    'throws $UnauthorizedMinecraftApiException on HTTP ${HttpStatus.unauthorized}',
    () async {
      if (isPostRequest) {
        mockDio().mockPostUriFailure<JsonObject>(
          statusCode: HttpStatus.unauthorized,
          responseData: {},
        );
      } else {
        mockDio().mockGetUriFailure<JsonObject>(
          statusCode: HttpStatus.unauthorized,
          responseData: {},
        );
      }

      await expectLater(
        call,
        throwsA(isA<UnauthorizedMinecraftApiException>()),
      );
    },
  );
}
