import 'package:meta/meta.dart';

import '../../../../../common/logic/utils.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../../../data/launcher_minecraft_account/minecraft_account.dart';
import '../../../../data/minecraft_account_api/minecraft_account_api.dart';
import '../../microsoft_refresh_token_expiration.dart';
import 'minecraft_account_resolver_exceptions.dart'
    as minecraft_account_resolver_exceptions;

/// Performs the necessary steps to authenticate a Microsoft account
/// with Minecraft, including:
///
/// * Exchanging the Microsoft access token for an Xbox token,
/// * Requesting an XSTS token using the Xbox token,
/// * Logging into Minecraft using the XSTS credentials,
/// * Verifying Minecraft ownership,
/// * Fetching the Minecraft profile (ID, name, skins, capes).
///
/// Runs regardless of the Microsoft authentication method used
/// (device code, auth code), or when refreshing an existing account.
///
/// Stateless and pure; does not cache or persist any data.
class MinecraftAccountResolver {
  MinecraftAccountResolver({
    required this.microsoftAuthApi,
    required this.minecraftAccountApi,
  });

  @visibleForTesting
  final MicrosoftAuthApi microsoftAuthApi;
  @visibleForTesting
  final MinecraftAccountApi minecraftAccountApi;

  Future<MinecraftAccount> resolve({
    required MicrosoftOAuthTokenResponse oauthTokenResponse,
    required ResolveMinecraftAccountProgressCallback onProgress,
  }) async {
    onProgress(ResolveMinecraftAccountProgress.requestingXboxToken);
    final xboxLiveTokenResponse = await microsoftAuthApi.requestXboxLiveToken(
      oauthTokenResponse.accessToken,
    );

    onProgress(ResolveMinecraftAccountProgress.requestingXstsToken);
    final xstsTokenResponse = await microsoftAuthApi.requestXSTSToken(
      xboxLiveTokenResponse.xboxToken,
    );
    onProgress(ResolveMinecraftAccountProgress.loggingIntoMinecraft);
    final minecraftLoginResponse = await minecraftAccountApi
        .loginToMinecraftWithXbox(
          xstsToken: xstsTokenResponse.xboxToken,
          xstsUserHash: xstsTokenResponse.userHash,
        );

    onProgress(ResolveMinecraftAccountProgress.checkingMinecraftJavaOwnership);
    final ownsMinecraftJava = await minecraftAccountApi
        .checkMinecraftJavaOwnership(minecraftLoginResponse.accessToken);

    if (!ownsMinecraftJava) {
      throw const minecraft_account_resolver_exceptions.MinecraftJavaEntitlementAbsentException();
    }

    onProgress(ResolveMinecraftAccountProgress.fetchingProfile);
    final minecraftProfileResponse = await minecraftAccountApi
        .fetchMinecraftProfile(minecraftLoginResponse.accessToken);

    final newAccount = accountFromResponses(
      profileResponse: minecraftProfileResponse,
      oauthTokenResponse: oauthTokenResponse,
      loginResponse: minecraftLoginResponse,
      ownsMinecraftJava: ownsMinecraftJava,
    );

    return newAccount;
  }

  @visibleForTesting
  MinecraftAccount accountFromResponses({
    required MinecraftProfileResponse profileResponse,
    required MicrosoftOAuthTokenResponse oauthTokenResponse,
    required MinecraftLoginResponse loginResponse,
    required bool ownsMinecraftJava,
  }) {
    MinecraftCosmeticState toCosmeticState(MinecraftApiCosmeticState api) =>
        switch (api) {
          MinecraftApiCosmeticState.active => MinecraftCosmeticState.active,
          MinecraftApiCosmeticState.inactive => MinecraftCosmeticState.inactive,
        };
    return MinecraftAccount(
      id: profileResponse.id,
      username: profileResponse.name,
      accountType: AccountType.microsoft,
      microsoftAccountInfo: MicrosoftAccountInfo(
        microsoftRefreshToken: ExpirableToken(
          value: oauthTokenResponse.refreshToken,
          expiresAt: microsoftRefreshTokenExpiresAt(),
        ),
        minecraftAccessToken: ExpirableToken(
          value: loginResponse.accessToken,
          expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
        ),
        // Account created and logged in; re-authentication is not required
        reauthRequiredReason: null,
      ),
      skins:
          profileResponse.skins
              .map(
                (skin) => MinecraftSkin(
                  id: skin.id,
                  state: toCosmeticState(skin.state),
                  url: skin.url,
                  textureKey: skin.textureKey,
                  variant: switch (skin.variant) {
                    MinecraftApiSkinVariant.classic =>
                      MinecraftSkinVariant.classic,
                    MinecraftApiSkinVariant.slim => MinecraftSkinVariant.slim,
                  },
                ),
              )
              .toList(),
      capes:
          profileResponse.capes
              .map(
                (cape) => MinecraftCape(
                  id: cape.id,
                  state: toCosmeticState(cape.state),
                  url: cape.url,
                  alias: cape.alias,
                ),
              )
              .toList(),
      ownsMinecraftJava: ownsMinecraftJava,
    );
  }
}

enum ResolveMinecraftAccountProgress {
  requestingXboxToken,
  requestingXstsToken,
  loggingIntoMinecraft,
  checkingMinecraftJavaOwnership,
  fetchingProfile,
}

typedef ResolveMinecraftAccountProgressCallback =
    void Function(ResolveMinecraftAccountProgress progress);
