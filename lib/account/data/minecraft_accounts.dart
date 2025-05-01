import 'package:meta/meta.dart';

import '../../common/logic/json.dart';
import '../../common/logic/utils.dart';
import 'minecraft_account.dart';

@immutable
class MinecraftAccounts {
  const MinecraftAccounts({
    required this.all,
    required this.defaultAccountIndex,
  });

  factory MinecraftAccounts.empty() =>
      const MinecraftAccounts(all: [], defaultAccountIndex: null);

  factory MinecraftAccounts.fromJson(JsonObject json) => MinecraftAccounts(
    defaultAccountIndex: json['defaultAccountIndex'] as int?,
    all:
        (json['accounts']! as List<dynamic>)
            .cast<JsonObject>()
            .map((jsonObject) => MinecraftAccount.fromJson(jsonObject))
            .toList(),
  );

  final List<MinecraftAccount> all;
  final int? defaultAccountIndex;

  MinecraftAccount? get defaultAccount =>
      defaultAccountIndex == null ? null : all[defaultAccountIndex!];

  MinecraftAccount get defaultAccountOrThrow =>
      defaultAccount ??
      (throw Exception(
        'Expected the current active Minecraft account to be not null',
      ));

  JsonObject toJson() => {
    'accounts': all.map((account) => account.toJson()).toList(),
    'defaultAccountIndex': defaultAccountIndex,
  };

  MinecraftAccounts copyWith({
    List<MinecraftAccount>? all,
    Wrapped<int?>? defaultAccountIndex,
  }) => MinecraftAccounts(
    all: all ?? this.all,
    defaultAccountIndex:
        defaultAccountIndex != null
            ? defaultAccountIndex.value
            : this.defaultAccountIndex,
  );
}
