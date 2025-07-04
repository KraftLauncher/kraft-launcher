import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_accounts.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_accounts.dart';

extension AccountsMapper on MinecraftAccounts {
  FileAccounts toFileModel({required bool storeTokensInFile}) => FileAccounts(
    accounts:
        list
            .map(
              (account) =>
                  account.toFileModel(storeTokensInFile: storeTokensInFile),
            )
            .toList(),
    defaultAccountId: defaultAccountId,
  );
}

extension AccountMapper on MinecraftAccount {
  FileAccount toFileModel({required bool storeTokensInFile}) => FileAccount(
    id: id,
    username: username,
    accountType: accountType,
    microsoftAccountInfo: microsoftAccountInfo?.toFileModel(
      storeTokensInFile: storeTokensInFile,
    ),
    skins: skins,
    capes: capes,
    ownsMinecraftJava: ownsMinecraftJava,
  );
}

extension _MicrosoftAccountInfoMapper on MicrosoftAccountInfo {
  FileMicrosoftAccountInfo toFileModel({required bool storeTokensInFile}) =>
      FileMicrosoftAccountInfo(
        microsoftRefreshToken: microsoftRefreshToken.toFileModel(
          storeTokenInFile: storeTokensInFile,
        ),
        minecraftAccessToken: minecraftAccessToken.toFileModel(
          storeTokenInFile: storeTokensInFile,
        ),
        accessRevoked:
            reauthRequiredReason == MicrosoftReauthRequiredReason.accessRevoked,
      );
}

extension _ExpirableToken on ExpirableToken {
  FileExpirableToken toFileModel({required bool storeTokenInFile}) =>
      FileExpirableToken(
        value: storeTokenInFile ? value : null,
        expiresAt: expiresAt,
      );
}
