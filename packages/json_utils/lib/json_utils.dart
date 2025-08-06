// Avoid showing the `json` property to ensure it
// will be not used by convert() or jsonDecode().
import 'dart:convert' show JsonEncoder, jsonDecode;

import 'package:result/result.dart';

typedef JsonMap = Map<String, Object?>;

typedef JsonList = List<dynamic>;

String jsonEncodePretty(JsonMap jsonMap) =>
    JsonEncoder.withIndent(' ' * 2).convert(jsonMap);

sealed class JsonParseFailure extends BaseFailure {
  const JsonParseFailure(super.message);
}

/// A failure that occurs while decoding the JSON String.
///
/// Indicates invalid or malformed JSON.
final class JsonDecodingFailure extends JsonParseFailure {
  const JsonDecodingFailure(String jsonInput, this.reason)
    : super('JSON decoding failed. Reason: $reason\nInput: $jsonInput');
  final String reason;
}

/// A failure that occurs while deserializing a decoded JSON object.
///
/// Indicates a structural or type mismatch between JSON and the expected model.
final class JsonDeserializationFailure extends JsonParseFailure {
  const JsonDeserializationFailure(this.decodedJson, this.reason)
    : super(
        'JSON deserialization failed. Reason: $reason\nInput: $decodedJson',
      );
  final String reason;
  final JsonMap decodedJson;
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

Result<T, JsonParseFailure> tryJsonParse<T>(
  String json,
  T Function(JsonMap json) fromJson,
) {
  final jsonDecodeResult = tryJsonDecode(json);

  final decoded = jsonDecodeResult.valueOrNull;
  if (decoded == null) {
    return Result.failure(jsonDecodeResult.failureOrThrow);
  }

  final jsonDeserializationResult = tryJsonDeserialize(
    decoded,
    (JsonMap decoded) => fromJson(decoded),
  );

  final deserialized = jsonDeserializationResult.valueOrNull;

  if (deserialized == null) {
    return Result.failure(jsonDeserializationResult.failureOrThrow);
  }

  return Result.success(deserialized);
}
