import 'package:equatable/equatable.dart';
import 'package:kraft_launcher/common/data/json.dart';
import 'package:kraft_launcher/common/functional/either.dart';
import 'package:kraft_launcher/launcher/data/minecraft_versions_api/models/api_minecraft_rule.dart';
import 'package:meta/meta.dart';

typedef StringOrConditionalArg = Either<String, ApiMinecraftConditionalArg>;
typedef StringOrStringList = Either<String, List<String>>;

@immutable
class ApiMinecraftVersionArgs extends Equatable {
  const ApiMinecraftVersionArgs({required this.game, required this.jvm});

  factory ApiMinecraftVersionArgs.fromJson(JsonMap json) =>
      ApiMinecraftVersionArgs(
        game: _parse(json['game']! as JsonList),
        jvm: _parse(json['jvm']! as JsonList),
      );

  static List<StringOrConditionalArg> _parse(JsonList value) {
    return value.cast<Object>().map((Object object) {
      if (object is String) {
        return StringOrConditionalArg.left(object);
      }
      if (object is JsonMap) {
        return StringOrConditionalArg.right(
          ApiMinecraftConditionalArg.fromJson(object),
        );
      }
      throw UnsupportedError(
        'Unexpected argument value from the API: $object of type ${object.runtimeType}. Expected a $List where each element is either a $String or $ApiMinecraftConditionalArg.',
      );
    }).toList();
  }

  final List<StringOrConditionalArg> game;
  final List<StringOrConditionalArg> jvm;

  @override
  List<Object?> get props => [game, jvm];
}

@immutable
class ApiMinecraftConditionalArg extends Equatable {
  const ApiMinecraftConditionalArg({required this.rules, required this.value});

  factory ApiMinecraftConditionalArg.fromJson(
    JsonMap json,
  ) => ApiMinecraftConditionalArg(
    rules: (json['rules']! as JsonList)
        .cast<JsonMap>()
        .map((ruleMap) => ApiMinecraftRule.fromJson(ruleMap))
        .toList(),
    value: () {
      final value = json['value']!;
      if (value is List) {
        return StringOrStringList.right(value.cast<String>());
      }
      if (value is String) {
        return StringOrStringList.left(value);
      }
      throw UnsupportedError(
        'Unexpected conditional argument value from the API: $value of type ${value.runtimeType}. Expected Either a ${List<String>} or $String.',
      );
    }(),
  );

  final List<ApiMinecraftRule> rules;
  final StringOrStringList value;

  @override
  List<Object?> get props => [rules, value];
}
