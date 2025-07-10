import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_accounts.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';

extension AccountsMapper on MinecraftAccounts {
  FileAccounts toFileDto({required bool storeTokensInFile}) => FileAccounts(
    accounts:
        list
            .map(
              (account) =>
                  account.toFileDto(storeTokensInFile: storeTokensInFile),
            )
            .toList(),
    defaultAccountId: defaultAccountId,
  );
}

extension AccountMapper on MinecraftAccount {
  FileAccount toFileDto({required bool storeTokensInFile}) => FileAccount(
    id: id,
    username: username,
    accountType: accountType,
    microsoftAccountInfo: microsoftAccountInfo?.toFileDto(
      storeTokensInFile: storeTokensInFile,
    ),
    skins: skins,
    capes: capes,
    ownsMinecraftJava: ownsMinecraftJava,
  );
}

extension _MicrosoftAccountInfoMapper on MicrosoftAccountInfo {
  FileMicrosoftAccountInfo toFileDto({required bool storeTokensInFile}) =>
      FileMicrosoftAccountInfo(
        microsoftRefreshToken: microsoftRefreshToken.toFileDto(
          storeTokenInFile: storeTokensInFile,
        ),
        minecraftAccessToken: minecraftAccessToken.toFileDto(
          storeTokenInFile: storeTokensInFile,
        ),
        accessRevoked:
            reauthRequiredReason == MicrosoftReauthRequiredReason.accessRevoked,
      );
}

extension _ExpirableToken on ExpirableToken {
  FileExpirableToken toFileDto({required bool storeTokenInFile}) =>
      FileExpirableToken(
        value: storeTokenInFile ? value : null,
        expiresAt: expiresAt,
      );
}
