import 'package:meta/meta.dart';

import '../../common/logic/json.dart';
import '../../common/logic/utils.dart';
import 'minecraft_account.dart';

@immutable
class MinecraftAccounts {
  const MinecraftAccounts({required this.list, required this.defaultAccountId});

  factory MinecraftAccounts.empty() =>
      const MinecraftAccounts(list: [], defaultAccountId: null);

  factory MinecraftAccounts.fromJson(JsonObject json) => MinecraftAccounts(
    defaultAccountId: json['defaultAccountId'] as String?,
    list:
        (json['accounts']! as List<dynamic>)
            .cast<JsonObject>()
            .map((jsonObject) => MinecraftAccount.fromJson(jsonObject))
            .toList(),
  );

  final List<MinecraftAccount> list;
  final String? defaultAccountId;

  MinecraftAccount? get defaultAccount =>
      defaultAccountId == null
          ? null
          : list.firstWhere((account) => account.id == defaultAccountId);

  MinecraftAccount get defaultAccountOrThrow =>
      defaultAccount ??
      (throw Exception(
        'Expected the current active Minecraft account to be not null',
      ));

  JsonObject toJson() => {
    'accounts': list.map((account) => account.toJson()).toList(),
    'defaultAccountId': defaultAccountId,
  };

  MinecraftAccounts copyWith({
    List<MinecraftAccount>? all,
    Wrapped<String?>? defaultAccountId,
  }) => MinecraftAccounts(
    list: all ?? list,
    defaultAccountId:
        defaultAccountId != null
            ? defaultAccountId.value
            : this.defaultAccountId,
  );
}
