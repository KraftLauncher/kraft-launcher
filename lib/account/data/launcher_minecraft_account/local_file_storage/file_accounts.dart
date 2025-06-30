import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/account/data/launcher_minecraft_account/local_file_storage/file_account.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:meta/meta.dart';

@immutable
class FileAccounts extends Equatable {
  const FileAccounts({required this.accounts, required this.defaultAccountId});

  factory FileAccounts.fromJson(JsonMap json) => FileAccounts(
    defaultAccountId: json['defaultAccountId'] as String?,
    accounts:
        (json['accounts']! as List<dynamic>)
            .cast<JsonMap>()
            .map((accountMap) => FileAccount.fromJson(accountMap))
            .toList(),
  );

  final List<FileAccount> accounts;
  final String? defaultAccountId;

  JsonMap toJson() => {
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'defaultAccountId': defaultAccountId,
  };

  @override
  List<Object?> get props => [accounts, defaultAccountId];
}
