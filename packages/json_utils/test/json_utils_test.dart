import 'package:json_utils/json_utils.dart';
import 'package:test/test.dart';

void main() {
  test('$JsonMap type is correct', () {
    final JsonMap json = {'id': 1};
    expect(json, isA<Map<String, Object?>>());
  });

  test('jsonEncodePretty returns the JSON correctly', () {
    final JsonMap json = {
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
