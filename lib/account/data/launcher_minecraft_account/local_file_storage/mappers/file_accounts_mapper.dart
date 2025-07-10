import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_account.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_accounts.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/secure_storage/secure_account_data.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';

// TODO: Rename all extension and file names of mappers
extension FileAccountsMapper on FileMinecraftAccounts {
  Future<MinecraftAccounts> mapToAppAsync(
    Future<MinecraftAccount> Function(FileMinecraftAccount account) transform,
  ) async {
    final futures = accounts.map(transform);
    return MinecraftAccounts(
      list: await Future.wait(futures),
      defaultAccountId: defaultAccountId,
    );
  }

  MinecraftAccounts toApp({
    required MicrosoftReauthRequiredReason? Function(
      FileMinecraftAccount account,
    )
    resolveMicrosoftReauthReason,
  }) => MinecraftAccounts(
    list:
        accounts
            .map(
              (account) => account.toApp(
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

extension FileAccountMapper on FileMinecraftAccount {
  MinecraftAccount toApp({
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
      microsoftAccountInfo: microsoftAccountInfo?.toApp(
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
  MicrosoftAccountInfo toApp({
    required SecureAccountData? secureAccountData,
    required MicrosoftReauthRequiredReason? reauthRequiredReason,
  }) => MicrosoftAccountInfo(
    microsoftRefreshToken: microsoftRefreshToken.toApp(
      secureAccountData?.microsoftRefreshToken,
    ),
    minecraftAccessToken: minecraftAccessToken.toApp(
      secureAccountData?.minecraftAccessToken,
    ),
    reauthRequiredReason: reauthRequiredReason,
  );
}

extension _FileExpirableToken on FileExpirableToken {
  ExpirableToken toApp(String? overrideTokenValue) => ExpirableToken(
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
