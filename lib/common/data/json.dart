// Avoid showing the "json" property; otherwise, a bug will be introduced silently.
import 'dart:convert' show JsonEncoder, jsonDecode;

import 'package:kraft_launcher/common/models/result.dart';

typedef JsonMap = Map<String, Object?>;

typedef JsonList = List<dynamic>;

String jsonEncodePretty(JsonMap json) =>
    JsonEncoder.withIndent(' ' * 2).convert(json);

final class JsonDeserializationFailure extends BaseFailure {
  const JsonDeserializationFailure(this.originalJson, this.reason)
    : super('Failed to parse JSON. Reason: $reason\nInput: $originalJson');
  final String originalJson;
  final String reason;
}

// TODO: Also add safeJsonParse which takes fromJson callback and depends on the result from tryJsonDecode (suggestion)?
// TODO: Replace all usages of jsonDecode with tryJsonDecode.
// TODO: Avoid letting DIO decoding the HTTP response so and decode the JSON string manaully using safeHttpApiCall instead?
Result<JsonMap, JsonDeserializationFailure> tryJsonDecode(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is JsonMap) {
      return Result.success(decoded);
    }
    if (decoded is List) {
      // Avoid root JSON lists because they require workarounds to add new properties.
      // All APIs here use JSON objects at the root.
      // Decoding JSON lists as root is not needed.
      throw ArgumentError.value(
        json,
        'json',
        'Expected a JSON object ($JsonMap) but got a JSON list. This is not supported.',
      );
    }
    throw ArgumentError.value(
      json,
      'json',
      'Expected a JSON object ($JsonMap) but got ${decoded.runtimeType}.',
    );
  } on FormatException catch (e) {
    return Result.failure(JsonDeserializationFailure(json, e.message));
  }
}
