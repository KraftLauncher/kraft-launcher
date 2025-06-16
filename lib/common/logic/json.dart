// Avoid showing the "json" property; otherwise, a bug will be introduced silently.
import 'dart:convert' show JsonEncoder;

// TODO: Rename to JsonMap?
typedef JsonObject = Map<String, Object?>;

String jsonEncodePretty(JsonObject json) =>
    JsonEncoder.withIndent(' ' * 2).convert(json);
