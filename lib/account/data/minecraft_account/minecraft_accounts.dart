import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../common/logic/utils.dart';
import 'minecraft_account.dart';

@immutable
class MinecraftAccounts extends Equatable {
  const MinecraftAccounts({required this.list, required this.defaultAccountId});

  factory MinecraftAccounts.empty() =>
      const MinecraftAccounts(list: [], defaultAccountId: null);

  final List<MinecraftAccount> list;
  final String? defaultAccountId;

  MinecraftAccount? get defaultAccount =>
      defaultAccountId == null
          ? null
          : list.firstWhere((account) => account.id == defaultAccountId);

  MinecraftAccount get defaultAccountOrThrow =>
      defaultAccount ??
      (throw StateError(
        'Expected the current active Minecraft account to be not null',
      ));

  MinecraftAccounts copyWith({
    List<MinecraftAccount>? list,
    Wrapped<String?>? defaultAccountId,
  }) => MinecraftAccounts(
    list: list ?? this.list,
    defaultAccountId:
        defaultAccountId != null
            ? defaultAccountId.value
            : this.defaultAccountId,
  );

  @override
  List<Object?> get props => [list, defaultAccountId];
}
