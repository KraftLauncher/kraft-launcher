import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../common/logic/json.dart';
import 'file_account.dart';

@immutable
class FileAccounts extends Equatable {
  const FileAccounts({required this.accounts, required this.defaultAccountId});

  factory FileAccounts.fromJson(JsonMap json) => FileAccounts(
    defaultAccountId: json['defaultAccountId'] as String?,
    accounts:
        (json['accounts']! as List<dynamic>)
            .cast<JsonMap>()
            .map((jsonObject) => FileAccount.fromJson(jsonObject))
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
