import 'dart:convert' show JsonEncoder hide json;

typedef JsonObject = Map<String, Object?>;

String jsonEncodePretty(JsonObject json) =>
    JsonEncoder.withIndent(' ' * 2).convert(json);
