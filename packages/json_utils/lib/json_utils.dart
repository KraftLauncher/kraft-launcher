// Avoid showing the `json` property to ensure it
// will be not used by convert() or jsonDecode().
import 'dart:convert' show JsonEncoder, jsonDecode;

import 'package:result/result.dart';

typedef JsonMap = Map<String, Object?>;

typedef JsonList = List<dynamic>;

String jsonEncodePretty(JsonMap jsonMap) =>
    JsonEncoder.withIndent(' ' * 2).convert(jsonMap);

final class JsonDecodingFailure extends BaseFailure {
  const JsonDecodingFailure(this.jsonInput, this.reason)
    : super('Failed to decode JSON. Reason: $reason\nInput: $jsonInput');
  final String jsonInput;
  final String reason;
}

Result<JsonMap, JsonDecodingFailure> tryJsonDecode(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is JsonMap) {
      return Result.success(decoded);
    }
    if (decoded is List) {
      // Avoid root JSON lists because they require workarounds to add new properties.
      // All APIs use JSON objects at the root.
      // Decoding JSON lists as root is not needed.
      throw ArgumentError.value(
        json,
        'json',
        'Expected a JSON object ($JsonMap) but got a JSON list. Root JSON lists are not supported.',
      );
    }
    throw ArgumentError.value(
      json,
      'json',
      'Expected a JSON object ($JsonMap) but got ${decoded.runtimeType}.',
    );
  } on FormatException catch (e) {
    return Result.failure(JsonDecodingFailure(json, e.message));
  }
}

final class JsonDeserializationFailure extends BaseFailure {
  const JsonDeserializationFailure(this.decodedJson, this.reason)
    : super(
        'Failed to deserialize JSON. Reason: $reason\nInput: $decodedJson',
      );
  final JsonMap decodedJson;
  final String reason;
}

Result<T, JsonDeserializationFailure> tryJsonDeserialize<T>(
  JsonMap decodedJson,
  T Function(JsonMap json) fromJson,
) {
  try {
    return Result.success(fromJson(decodedJson));
    // fromJson() often uses 'as' and '!' operators, which can throw if the JSON
    // doesn't match the expected structure. This catches those errors as failures.
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    return Result.failure(
      JsonDeserializationFailure(decodedJson, e.toString()),
    );
  }
}
