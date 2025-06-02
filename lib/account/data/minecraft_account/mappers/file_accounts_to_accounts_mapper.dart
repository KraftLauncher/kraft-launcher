import '../local_file_storage/file_account.dart';
import '../local_file_storage/file_accounts.dart';
import '../minecraft_account.dart';
import '../minecraft_accounts.dart';
import '../secure_storage/secure_account_data.dart';

extension FileAccountsMapper on FileAccounts {
  Future<MinecraftAccounts> mapToAccountsAsync(
    Future<MinecraftAccount> Function(FileAccount account) transform,
  ) async {
    final futures = accounts.map(transform);
    return MinecraftAccounts(
      list: await Future.wait(futures),
      defaultAccountId: defaultAccountId,
    );
  }

  MinecraftAccounts toAccounts({
    required MicrosoftReauthRequiredReason? Function(FileAccount account)
    resolveMicrosoftReauthReason,
  }) => MinecraftAccounts(
    list:
        accounts
            .map(
              (account) => account.toAccount(
                secureAccountData: null,
                microsoftReauthRequiredReason: resolveMicrosoftReauthReason(
                  account,
                ),
              ),
            )
            .toList(),
    defaultAccountId: defaultAccountId,
  );
}

extension FileAccountMapper on FileAccount {
  MinecraftAccount toAccount({
    required SecureAccountData? secureAccountData,
    required MicrosoftReauthRequiredReason? microsoftReauthRequiredReason,
  }) {
    if (accountType == AccountType.offline) {
      if (secureAccountData != null) {
        throw ArgumentError.value(
          secureAccountData,
          'secureAccountData',
          'must be null for offline accounts',
        );
      }
      if (microsoftReauthRequiredReason != null) {
        throw ArgumentError.value(
          microsoftReauthRequiredReason,
          'microsoftReauthRequiredReason',
          'must be null for offline accounts',
        );
      }
    }
    return MinecraftAccount(
      id: id,
      username: username,
      accountType: accountType,
      microsoftAccountInfo: microsoftAccountInfo?.toMicrosoftAccountInfo(
        secureAccountData: secureAccountData,
        reauthRequiredReason: microsoftReauthRequiredReason,
      ),
      skins: skins,
      capes: capes,
      ownsMinecraftJava: ownsMinecraftJava,
    );
  }
}

extension _FileMicrosoftAccountInfoMapper on FileMicrosoftAccountInfo {
  MicrosoftAccountInfo toMicrosoftAccountInfo({
    required SecureAccountData? secureAccountData,
    required MicrosoftReauthRequiredReason? reauthRequiredReason,
  }) => MicrosoftAccountInfo(
    microsoftOAuthRefreshToken: microsoftOAuthRefreshToken.toExpirableToken(
      secureAccountData?.microsoftRefreshToken,
    ),
    minecraftAccessToken: minecraftAccessToken.toExpirableToken(
      secureAccountData?.minecraftAccessToken,
    ),
    reauthRequiredReason: reauthRequiredReason,
  );
}

extension _FileExpirableToken on FileExpirableToken {
  ExpirableToken toExpirableToken(String? overrideTokenValue) => ExpirableToken(
    value: overrideTokenValue ?? value,
    // Previously, the launcher didn't handle the case where the tokens are null in secure storage.
    // This issue will happen in portable mode so it has be handled.
    // (throw StateError(
    //   'Attempted to convert a $FileExpirableToken to $ExpirableToken, but the token is not stored on the file system and no fallback value was provided.'
    //   ' This can happen in portable mode, or if the secrets were removed without removing the account.',
    // )),
    expiresAt: expiresAt,
  );
}
