import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_minecraft_account.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:meta/meta.dart';

@immutable
class FileMinecraftAccounts extends Equatable {
  const FileMinecraftAccounts({
    required this.accounts,
    required this.defaultAccountId,
  });

  factory FileMinecraftAccounts.fromJson(JsonMap json) => FileMinecraftAccounts(
    defaultAccountId: json['defaultAccountId'] as String?,
    accounts:
        (json['accounts']! as JsonList)
            .cast<JsonMap>()
            .map((accountMap) => FileMinecraftAccount.fromJson(accountMap))
            .toList(),
  );

  final List<FileMinecraftAccount> accounts;
  final String? defaultAccountId;

  JsonMap toJson() => {
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'defaultAccountId': defaultAccountId,
  };

  @override
  List<Object?> get props => [accounts, defaultAccountId];
}
