import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/logic/json.dart';
import 'package:kraft_launcher/common/models/either.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/minecraft_rule.dart';
import 'package:meta/meta.dart';

@immutable
class MinecraftVersionArgs extends Equatable {
  const MinecraftVersionArgs({required this.game, required this.jvm});

  factory MinecraftVersionArgs.fromJson(JsonMap json) => MinecraftVersionArgs(
    game: _parse(json['game']! as JsonList),
    jvm: _parse(json['jvm']! as JsonList),
  );

  static List<Either<String, MinecraftConditionalArg>> _parse(JsonList value) {
    return value.cast<Object>().map((Object object) {
      if (object is String) {
        return Either<String, MinecraftConditionalArg>.left(object);
      }
      if (object is JsonMap) {
        return Either<String, MinecraftConditionalArg>.right(
          MinecraftConditionalArg.fromJson(object),
        );
      }
      throw UnsupportedError(
        'Unexpected argument value from the API: $object of type ${object.runtimeType}. Expected a $List where each element is either a $String or $MinecraftConditionalArg.',
      );
    }).toList();
  }

  final List<Either<String, MinecraftConditionalArg>> game;
  final List<Either<String, MinecraftConditionalArg>> jvm;

  @override
  List<Object?> get props => [game, jvm];
}

@immutable
class MinecraftConditionalArg extends Equatable {
  const MinecraftConditionalArg({required this.rules, required this.value});

  factory MinecraftConditionalArg.fromJson(
    JsonMap json,
  ) => MinecraftConditionalArg(
    rules:
        (json['rules']! as JsonList)
            .cast<JsonMap>()
            .map((ruleMap) => MinecraftRule.fromJson(ruleMap))
            .toList(),
    value: () {
      final value = json['value']!;
      if (value is List) {
        return Either<String, List<String>>.right(value.cast<String>());
      }
      if (value is String) {
        return Either<String, List<String>>.left(value);
      }
      throw UnsupportedError(
        'Unexpected conditional argument value from the API: $value of type ${value.runtimeType}. Expected Either a ${List<String>} or $String.',
      );
    }(),
  );

  final List<MinecraftRule> rules;
  final Either<String, List<String>> value;

  @override
  List<Object?> get props => [rules, value];
}
