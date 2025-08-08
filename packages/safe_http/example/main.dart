// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'package:json_utils/json_utils.dart';
import 'package:safe_http/src/api_client/api_client.dart';
import 'package:safe_http/src/api_client/http_package/http_api_client.dart';

void main() async {
  // Http package client
  final client = http.Client();

  try {
    // Use http package implementation
    final ApiClient apiClient = HttpApiClient(client);

    final result = await apiClient.request(
      Uri.https('example.com'),
      method: HttpMethod.get,
    );

    print('Result 1: $result\n\n');

    final result2 = await apiClient.requestJson(
      Uri.https('httpbin.org', 'post', {'name': 'test'}),
      method: HttpMethod.post,
      isJsonBody: true,
      headers: {'Authorization': 'Bearer e_2323'},
      body: {'username': 'User', 'password': '123'},
      deserializeSuccess: (response) =>
          _HttpBinPostResponse.fromJson(response.body),
      deserializeFailure: (response) => response.body,
    );

    print('Result 2: $result2');
  } finally {
    client.close();
  }
}

// Dummy class
class _HttpBinPostResponse {
  _HttpBinPostResponse({
    required this.args,
    required this.headers,
    required this.origin,
    required this.url,
  });

  factory _HttpBinPostResponse.fromJson(JsonMap json) {
    return _HttpBinPostResponse(
      args: Map<String, String>.from(json['args']! as JsonMap),
      headers: Map<String, String>.from(json['headers']! as JsonMap),
      origin: json['origin']! as String,
      url: json['url']! as String,
    );
  }
  final Map<String, String> args;
  final Map<String, String> headers;
  final String origin;
  final String url;

  JsonMap toJson() {
    return {'args': args, 'headers': headers, 'origin': origin, 'url': url};
  }

  @override
  String toString() => jsonEncodePretty(toJson());
}
