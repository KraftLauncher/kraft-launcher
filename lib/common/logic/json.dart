// Avoid showing the "json" property; otherwise, a bug will be introduced silently.
import 'dart:convert' show JsonEncoder;

typedef JsonMap = Map<String, Object?>;

String jsonEncodePretty(JsonMap json) =>
    JsonEncoder.withIndent(' ' * 2).convert(json);
