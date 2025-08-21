import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/functional/either.dart';
import 'package:kraft_launcher/launcher/logic/minecraft_versions/models/minecraft_rule.dart';
import 'package:meta/meta.dart';

typedef StringOrConditionalArg = Either<String, MinecraftConditionalArg>;
typedef StringOrStringList = Either<String, List<String>>;

@immutable
class MinecraftVersionArgs extends Equatable {
  const MinecraftVersionArgs({required this.game, required this.jvm});

  final List<StringOrConditionalArg> game;
  final List<StringOrConditionalArg> jvm;

  @override
  List<Object?> get props => [game, jvm];
}

@immutable
class MinecraftConditionalArg extends Equatable {
  const MinecraftConditionalArg({required this.rules, required this.value});

  final List<MinecraftRule> rules;
  final StringOrStringList value;

  @override
  List<Object?> get props => [rules, value];
}
