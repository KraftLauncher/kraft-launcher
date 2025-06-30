import 'package:meta/meta.dart';

import '../../../../../common/logic/utils.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api.dart';
import '../../../../data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import '../../../../data/minecraft_account_api/minecraft_account_api.dart';
import '../../../launcher_minecraft_account/minecraft_account.dart';
import '../../../minecraft_skin_ext.dart';
import '../../microsoft_refresh_token_expiration.dart';
import '../account_resolver/minecraft_account_resolver.dart';
import 'image_cache_service/image_cache_service.dart';
import 'minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;

/// Handles the token refresh flow for Microsoft-based Minecraft
/// accounts authenticated via Microsoft OAuth.
///
/// Runs regardless of the Microsoft authentication flow used
/// (device code or auth code).
///
/// Stateless and pure; does not cache or persist any data.
class MinecraftAccountRefresher {
  MinecraftAccountRefresher({
    required this.imageCacheService,
    required this.microsoftAuthApi,
    required this.minecraftAccountApi,
    required this.accountResolver,
  });

  final ImageCacheService imageCacheService;
  final MicrosoftAuthApi microsoftAuthApi;
  final MinecraftAccountApi minecraftAccountApi;
  final MinecraftAccountResolver accountResolver;

  Future<MinecraftAccount> refreshMicrosoftAccount(
    MinecraftAccount account, {
    required RefreshMinecraftAccountProgressCallback onRefreshProgress,
    required ResolveMinecraftAccountProgressCallback onResolveAccountProgress,
  }) async {
    assert(
      account.accountType == AccountType.microsoft,
      'Expected the account type to be Microsoft, but received: ${account.accountType.name}',
    );

    final microsoftAccountInfo = account.microsoftAccountInfo;
    if (microsoftAccountInfo == null) {
      throw ArgumentError.value(
        account,
        'account',
        'The $MicrosoftAccountInfo must not be null when refreshing'
            ' the Microsoft account. Account Type: ${account.accountType.name}',
      );
    }

    _throwsIfNeedsMicrosoftReAuth(account);

    final microsoftRefreshToken =
        microsoftAccountInfo.microsoftRefreshToken.value ??
        (throw StateError(
          'Microsoft refresh token should not be null to refresh the account',
        ));

    try {
      onRefreshProgress(
        RefreshMinecraftAccountProgress.refreshingMicrosoftTokens,
      );
      final oauthTokenResponse = await microsoftAuthApi
          .getNewTokensFromRefreshToken(microsoftRefreshToken);

      // Delete current cached skin images.
      await imageCacheService.evictFromCache(account.headSkinImageUrl);
      await imageCacheService.evictFromCache(account.fullSkinImageUrl);

      return await accountResolver.resolve(
        oauthTokenResponse: oauthTokenResponse,
        onProgress: onResolveAccountProgress,
      );
    } on microsoft_auth_api_exceptions.InvalidRefreshTokenException {
      final updatedAccount = account.copyWith(
        microsoftAccountInfo: microsoftAccountInfo.copyWith(
          reauthRequiredReason: MicrosoftReauthRequiredReason.accessRevoked,
        ),
      );
      throw minecraft_account_refresher_exceptions.InvalidMicrosoftRefreshTokenException(
        updatedAccount,
      );
    }
  }

  // Refreshes a Microsoft account if the Minecraft access token is expired.
  // TODO: More consideration is needed, test it with skin update feature first.
  //  Manually test handling of Microsoft refresh token expiration

  @experimental
  Future<MinecraftAccount> refreshMinecraftAccessTokenIfExpired(
    MinecraftAccount account, {
    required RefreshMinecraftAccessTokenProgressCallback onRefreshProgress,
  }) async {
    final microsoftAccountInfo = account.microsoftAccountInfo;
    if (microsoftAccountInfo == null) {
      throw ArgumentError.value(
        account,
        'account',
        'The $MicrosoftAccountInfo must not be null when validating the '
            'Minecraft access token. Account Type: ${account.accountType.name}',
      );
    }
    final hasExpired =
        microsoftAccountInfo.minecraftAccessToken.expiresAt.hasExpired;
    if (hasExpired) {
      _throwsIfNeedsMicrosoftReAuth(account);

      final microsoftRefreshToken =
          microsoftAccountInfo.microsoftRefreshToken.value ??
          (throw StateError(
            'Microsoft refresh token should not be null to refresh the Minecraft access token',
          ));

      onRefreshProgress(
        RefreshMinecraftAccessTokenProgress.refreshingMicrosoftTokens,
      );
      final response = await microsoftAuthApi.getNewTokensFromRefreshToken(
        microsoftRefreshToken,
      );

      // TODO: Part of  MinecraftAccountResolver logic (Xbox → XSTS → Login)
      //  is duplicated in here just to avoid the full profile resolution.
      //  We may need to refactor some of the code for a better solution.

      onRefreshProgress(
        RefreshMinecraftAccessTokenProgress.requestingXboxToken,
      );
      final xboxResponse = await microsoftAuthApi.requestXboxLiveToken(
        response.accessToken,
      );

      onRefreshProgress(
        RefreshMinecraftAccessTokenProgress.requestingXstsToken,
      );
      final xstsTokenResponse = await microsoftAuthApi.requestXSTSToken(
        xboxResponse.xboxToken,
      );

      onRefreshProgress(
        RefreshMinecraftAccessTokenProgress.loggingIntoMinecraft,
      );
      final loginResponse = await minecraftAccountApi.loginToMinecraftWithXbox(
        xstsToken: xstsTokenResponse.xboxToken,
        xstsUserHash: xstsTokenResponse.userHash,
      );
      final refreshedAccount = account.copyWith(
        microsoftAccountInfo: microsoftAccountInfo.copyWith(
          minecraftAccessToken: ExpirableToken(
            value: loginResponse.accessToken,
            expiresAt: expiresInToExpiresAt(loginResponse.expiresIn),
          ),
          microsoftRefreshToken: ExpirableToken(
            value: response.refreshToken,
            expiresAt: microsoftRefreshTokenExpiresAt(),
          ),
        ),
      );

      return refreshedAccount;
    }
    return account;
  }

  void _throwsIfNeedsMicrosoftReAuth(MinecraftAccount account) {
    final reAuthRequiredReason =
        account.microsoftAccountInfo?.reauthRequiredReason;
    if (reAuthRequiredReason != null) {
      throw minecraft_account_refresher_exceptions.MicrosoftReAuthRequiredException(
        reAuthRequiredReason,
      );
    }
    // NOTE: Microsoft refresh token expiration (after 90 days) is checked when loading accounts.
    // In rare cases, a token might expire shortly after loading but before use.
    // We accept this edge case to keep the logic simple.
  }
}

enum RefreshMinecraftAccountProgress { refreshingMicrosoftTokens }

typedef RefreshMinecraftAccountProgressCallback =
    void Function(RefreshMinecraftAccountProgress progress);

typedef RefreshMinecraftAccessTokenProgressCallback =
    void Function(RefreshMinecraftAccessTokenProgress progress);

enum RefreshMinecraftAccessTokenProgress {
  refreshingMicrosoftTokens,
  requestingXboxToken,
  requestingXstsToken,
  loggingIntoMinecraft,
}
