import '../local_file_storage/file_account.dart';
import '../local_file_storage/file_accounts.dart';
import '../minecraft_account.dart';
import '../minecraft_accounts.dart';

extension AccountsMapper on MinecraftAccounts {
  FileAccounts toFileAccounts({
    required bool storeTokensInFile,
  }) => FileAccounts(
    accounts:
        list
            .map(
              (account) =>
                  account.toFileAccount(storeTokensInFile: storeTokensInFile),
            )
            .toList(),
    defaultAccountId: defaultAccountId,
  );
}

extension AccountMapper on MinecraftAccount {
  FileAccount toFileAccount({required bool storeTokensInFile}) => FileAccount(
    id: id,
    username: username,
    accountType: accountType,
    microsoftAccountInfo: microsoftAccountInfo?.toFileMicrosoftAccountInfo(
      storeTokensInFile: storeTokensInFile,
    ),
    skins: skins,
    capes: capes,
    ownsMinecraftJava: ownsMinecraftJava,
  );
}

extension _MicrosoftAccountInfoMapper on MicrosoftAccountInfo {
  FileMicrosoftAccountInfo toFileMicrosoftAccountInfo({
    required bool storeTokensInFile,
  }) => FileMicrosoftAccountInfo(
    microsoftRefreshToken: microsoftRefreshToken.toFileExpirableToken(
      storeTokenInFile: storeTokensInFile,
    ),
    minecraftAccessToken: minecraftAccessToken.toFileExpirableToken(
      storeTokenInFile: storeTokensInFile,
    ),
    accessRevoked:
        reauthRequiredReason == MicrosoftReauthRequiredReason.accessRevoked,
  );
}

extension _ExpirableToken on ExpirableToken {
  FileExpirableToken toFileExpirableToken({required bool storeTokenInFile}) =>
      FileExpirableToken(
        value: storeTokenInFile ? value : null,
        expiresAt: expiresAt,
      );
}
