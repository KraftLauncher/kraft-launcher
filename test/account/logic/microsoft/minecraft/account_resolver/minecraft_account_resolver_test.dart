import 'package:clock/clock.dart';
import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver.dart';
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver_exceptions.dart'
    as minecraft_account_resolver_exceptions;
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../../common/helpers/mocks.dart';
import '../../../../../common/test_constants.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api_dummy_values.dart';

void main() {
  late MockMicrosoftAuthApi mockMicrosoftAuthApi;
  late MockMinecraftAccountApi mockMinecraftAccountApi;
  late MinecraftAccountResolver resolver;

  void mockLoginToMinecraftWithXbox(
    MinecraftLoginResponse minecraftLoginResponse,
  ) {
    when(
      () => mockMinecraftAccountApi.loginToMinecraftWithXbox(
        xstsToken: any(named: 'xstsToken'),
        xstsUserHash: any(named: 'xstsUserHash'),
      ),
    ).thenAnswer((_) async => minecraftLoginResponse);
  }

  setUp(() {
    mockMicrosoftAuthApi = MockMicrosoftAuthApi();
    mockMinecraftAccountApi = MockMinecraftAccountApi();

    resolver = MinecraftAccountResolver(
      microsoftAuthApi: mockMicrosoftAuthApi,
      minecraftAccountApi: mockMinecraftAccountApi,
    );

    when(() => mockMinecraftAccountApi.fetchMinecraftProfile(any())).thenAnswer(
      (_) async => const MinecraftProfileResponse(
        id: TestConstants.anyString,
        name: TestConstants.anyString,
        skins: [],
        capes: [],
      ),
    );

    when(
      () => mockMicrosoftAuthApi.requestXboxLiveToken(any()),
    ).thenAnswer((_) async => dummyXboxLiveAuthTokenResponse);
    when(
      () => mockMicrosoftAuthApi.requestXSTSToken(any()),
    ).thenAnswer((_) async => dummyXboxLiveAuthTokenResponse);
    mockLoginToMinecraftWithXbox(
      const MinecraftLoginResponse(
        username: TestConstants.anyString,
        accessToken: TestConstants.anyString,
        expiresIn: TestConstants.anyInt,
      ),
    );

    when(
      () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(any()),
    ).thenAnswer((_) async => false);
  });

  Future<MinecraftAccount> resolve({
    MicrosoftOAuthTokenResponse? tokenResponse,
    ResolveMinecraftAccountProgressCallback? onProgress,
  }) => resolver.resolve(
    oauthTokenResponse: tokenResponse ?? dummyMicrosoftOAuthTokenResponse,
    onProgress: onProgress ?? (_) {},
  );

  test(
    'calls APIs correctly in order from Microsoft OAuth access token to Minecraft profile',
    () async {
      const xboxTokenResponse = XboxLiveAuthTokenResponse(
        xboxToken: 'example-xbox-token',
        userHash: 'example-xbox-user-hash',
      );
      const xstsTokenResponse = XboxLiveAuthTokenResponse(
        xboxToken: 'example-xsts-token',
        userHash: 'example-xsts-user-hash',
      );

      const minecraftLoginResponse = MinecraftLoginResponse(
        username: 'example_user',
        accessToken: 'example-minecraft-access-token',
        expiresIn: 9600,
      );

      when(
        () => mockMicrosoftAuthApi.requestXboxLiveToken(any()),
      ).thenAnswer((_) async => xboxTokenResponse);
      when(
        () => mockMicrosoftAuthApi.requestXSTSToken(any()),
      ).thenAnswer((_) async => xstsTokenResponse);

      mockLoginToMinecraftWithXbox(minecraftLoginResponse);

      when(
        () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(any()),
      ).thenAnswer((_) async => true);

      final progressEvents = <ResolveMinecraftAccountProgress>[];

      const microsoftAccessToken = 'example-microsoft-access-token';

      await resolve(
        tokenResponse: const MicrosoftOAuthTokenResponse(
          accessToken: microsoftAccessToken,
          refreshToken: TestConstants.anyString,
          expiresIn: TestConstants.anyInt,
        ),
        onProgress: (progress) => progressEvents.add(progress),
      );

      expect(progressEvents, [
        ResolveMinecraftAccountProgress.requestingXboxToken,
        ResolveMinecraftAccountProgress.requestingXstsToken,
        ResolveMinecraftAccountProgress.loggingIntoMinecraft,
        ResolveMinecraftAccountProgress.checkingMinecraftJavaOwnership,
        ResolveMinecraftAccountProgress.fetchingProfile,
      ]);
      verifyInOrder([
        () => mockMicrosoftAuthApi.requestXboxLiveToken(
          any(that: same(microsoftAccessToken)),
        ),
        () => mockMicrosoftAuthApi.requestXSTSToken(
          any(that: same(xboxTokenResponse.xboxToken)),
        ),
        () => mockMinecraftAccountApi.loginToMinecraftWithXbox(
          xstsToken: any(
            that: same(xstsTokenResponse.xboxToken),
            named: 'xstsToken',
          ),
          xstsUserHash: any(
            that: same(xstsTokenResponse.userHash),
            named: 'xstsUserHash',
          ),
        ),
        () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(
          minecraftLoginResponse.accessToken,
        ),
        () => mockMinecraftAccountApi.fetchMinecraftProfile(
          minecraftLoginResponse.accessToken,
        ),
      ]);
      verifyNoMoreInteractions(mockMicrosoftAuthApi);
      verifyNoMoreInteractions(mockMinecraftAccountApi);
    },
  );

  test(
    'ownsMinecraftJava is true when the user have a valid copy of the game',
    () async {
      const ownsMinecraftJava = true;
      when(
        () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(any()),
      ).thenAnswer((_) async => ownsMinecraftJava);

      final account = await resolve();
      expect(account.ownsMinecraftJava, ownsMinecraftJava);
    },
  );

  test(
    'throws ${minecraft_account_resolver_exceptions.MinecraftAccountResolverException} when the user dont have a valid copy of the game',
    () async {
      const ownsMinecraftJava = false;
      when(
        () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(any()),
      ).thenAnswer((_) async => ownsMinecraftJava);

      await expectLater(
        resolve(),
        throwsA(
          isA<
            minecraft_account_resolver_exceptions.MinecraftAccountResolverException
          >(),
        ),
      );
    },
  );

  test('returns Minecraft account correctly based on API responses', () async {
    const tokenResponse = MicrosoftOAuthTokenResponse(
      accessToken: TestConstants.anyString,
      refreshToken: 'example-microsoft-refresh-token',
      expiresIn: TestConstants.anyInt,
    );
    const minecraftLoginResponse = MinecraftLoginResponse(
      username: 'example_username',
      accessToken: 'example-minecraft-access-token',
      expiresIn: 9600,
    );

    const minecraftProfileResponse = MinecraftProfileResponse(
      id: 'example-minecraft-id',
      name: 'example_minecraft_username',
      skins: [
        MinecraftProfileSkin(
          id: 'example-minecraft-skin-id-1',
          state: MinecraftApiCosmeticState.inactive,
          url: 'http://example_skin_1.png',
          textureKey:
              'example-a56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7e',
          variant: MinecraftApiSkinVariant.slim,
        ),
        MinecraftProfileSkin(
          id: 'example-minecraft-skin-id-2',
          state: MinecraftApiCosmeticState.active,
          url: 'http://example_skin_2.png',
          textureKey:
              'example-b56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7c',
          variant: MinecraftApiSkinVariant.classic,
        ),
      ],
      capes: [
        MinecraftProfileCape(
          id: 'example-minecraft-cape-id-1',
          state: MinecraftApiCosmeticState.active,
          url: 'http://example_cape_1.png',
          alias:
              'example-a56acf72e21996071218ba95ad42b70507628aa6ac13f08476dd601d96902b7y',
        ),
      ],
    );

    const ownsMinecraftJava = true;
    mockLoginToMinecraftWithXbox(minecraftLoginResponse);

    when(
      () => mockMinecraftAccountApi.fetchMinecraftProfile(any()),
    ).thenAnswer((_) async => minecraftProfileResponse);
    when(
      () => mockMinecraftAccountApi.checkMinecraftJavaOwnership(any()),
    ).thenAnswer((_) async => ownsMinecraftJava);

    final fixedDateTime = DateTime(2080, 8, 3, 10);
    await withClock(Clock.fixed(fixedDateTime), () async {
      final account = await resolve(tokenResponse: tokenResponse);
      final microsoftAccountInfo = account.microsoftAccountInfo;

      expect(
        microsoftAccountInfo?.minecraftAccessToken.expiresAt,
        fixedDateTime.add(Duration(seconds: minecraftLoginResponse.expiresIn)),
        reason:
            'The minecraftAccessToken should be: current date + ${minecraftLoginResponse.expiresIn}s which is the expiresIn from the API response',
      );
      expect(
        microsoftAccountInfo?.microsoftRefreshToken.expiresAt,
        fixedDateTime.add(
          const Duration(days: MicrosoftConstants.refreshTokenExpiresInDays),
        ),
        reason:
            'The microsoftRefreshToken should be: current date + ${MicrosoftConstants.refreshTokenExpiresInDays} days',
      );

      expect(
        account,
        resolver.accountFromResponses(
          profileResponse: minecraftProfileResponse,
          oauthTokenResponse: tokenResponse,
          loginResponse: minecraftLoginResponse,
          ownsMinecraftJava: ownsMinecraftJava,
        ),
      );
    });
  });
}
