import 'package:kraft_launcher/common/logic/json.dart';
import 'package:test/test.dart';

void main() {
  test('$JsonObject type is correct', () {
    final JsonObject json = {'id': 1};
    expect(json, isA<Map<String, Object?>>());
  });

  test('jsonEncodePretty returns the JSON correctly', () {
    final JsonObject json = {
      'id': 0,
      'name': 'Steve',
      'image': null,
      'ownsMinecraft': true,
    };
    expect(jsonEncodePretty(json), '''
{
  "id": 0,
  "name": "Steve",
  "image": null,
  "ownsMinecraft": true
}''');
  });
}
