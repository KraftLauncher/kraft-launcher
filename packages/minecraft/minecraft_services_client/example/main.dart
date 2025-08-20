import 'dart:io';

import 'package:api_client/api_client.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' show Client;
import 'package:minecraft_services_client/minecraft_services_client.dart';
import 'package:result/result.dart';

void main() async {
  final client = Client();

  try {
    final ApiClient apiClient = HttpApiClient(client);

    final MinecraftServicesApiClient minecraftServicesApiClient =
        HttpMinecraftServicesApiClient(apiClient: apiClient);

    stdout.write(
      'This program checks whether you have a valid license of "Minecraft: Java edition".\n',
    );
    stdout.write('Enter the Minecraft access token: ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.trim().isEmpty) {
      stderr.writeln('❌ No input provided.');
      exit(1);
    }

    final result = await minecraftServicesApiClient.fetchEntitlements(
      accessToken: input,
    );

    switch (result) {
      case SuccessResult<
        HttpResponse<MinecraftEntitlementsResponse>,
        ApiFailure<MinecraftErrorResponse>
      >(
        :final value,
      ):
        final body = value.body;

        final ownsMinecraftJava = body.items.any(
          (e) => e.name == 'game_minecraft',
        );
        stdout.writeln(
          '✅ You ${ownsMinecraftJava ? 'do' : "don't"} have a valid license of Minecraft: Java edition.',
        );

      case FailureResult<
        HttpResponse<MinecraftEntitlementsResponse>,
        ApiFailure<MinecraftErrorResponse>
      >():
        switch (result.failure) {
          case ConnectionFailure<MinecraftErrorResponse>():
            stderr.writeln('❌ Failed to connect to $_host.');
          case HttpStatusFailure<MinecraftErrorResponse>(:final response):
            if (response.statusCode == 401) {
              stderr.writeln(
                '❌ Unauthorized access, please refresh your Minecraft access token.\n',
              );
            }
            stderr.writeln('❌ $_host returned: $response.');
          case UnknownFailure<MinecraftErrorResponse>():
            stderr.writeln(
              '❌ An unknown error while sending a request to $_host.',
            );
          case JsonDecodingFailure<MinecraftErrorResponse>():
            stderr.writeln(
              '❌ The API $_host returned malformed or invalid JSON.',
            );
          case JsonDeserializationFailure<MinecraftErrorResponse>():
            stderr.writeln('❌ Failed to deserialize the JSON from $_host.');
        }
    }
  } finally {
    client.close();
  }
}

const _host = MinecraftServicesApiClient.baseUrlHost;
