// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:api_client/api_client.dart' show ApiClient, HttpApiClient;
import 'package:http/http.dart' show Client;
import 'package:minecraft_services_client/minecraft_services_client.dart'
    show HttpMinecraftServicesApiClient, MinecraftServicesApiClient;
import 'package:minecraft_services_repository/minecraft_services_repository.dart';
import 'package:result/result.dart';

void main() async {
  final client = Client();

  try {
    final ApiClient apiClient = HttpApiClient(client);

    final MinecraftServicesApiClient minecraftServicesApiClient =
        HttpMinecraftServicesApiClient(apiClient: apiClient);

    final MinecraftServicesRepository minecraftServicesRepository =
        DefaultMinecraftServicesRepository(
          apiClient: minecraftServicesApiClient,
        );

    stdout.write(
      'This program checks whether you have a valid license for "Minecraft: Java Edition".\n',
    );
    stdout.write('Enter your Minecraft access token: ');
    final input = stdin.readLineSync()?.trim();

    if (input == null || input.isEmpty) {
      stderr.writeln('❌ No input provided.');
      exit(1);
    }

    final result = await minecraftServicesRepository
        .hasValidMinecraftJavaLicense(accessToken: input);

    switch (result) {
      case SuccessResult<bool, MinecraftServicesFailure>(:final value):
        final ownsMinecraftJava = value;

        stdout.writeln(
          '✅ You ${ownsMinecraftJava ? 'have' : "do not have"} a valid license for Minecraft: Java Edition.',
        );
      case FailureResult<bool, MinecraftServicesFailure>():
        switch (result.failure) {
          case ConnectionFailure():
            stderr.writeln('❌ Failed to connect to Minecraft services.');
          case UnexpectedFailure():
            stderr.writeln(
              '❌ An unexpected error occurred while sending a request to Minecraft services.',
            );
          case UnhandledServerResponseFailure(:final message):
            stderr.writeln(
              '❌ An unhandled server response from the Minecraft services:\n'
              '$message',
            );
          case UnauthorizedAccessFailure():
            stderr.writeln(
              '❌ Unauthorized access. Please refresh your Minecraft access token.\n',
            );
          case TooManyRequestsFailure():
            stderr.writeln(
              '❌ Too many requests have been sent to Minecraft services.\n',
            );
          case AccountNotFoundFailure():
            stderr.writeln('❌ Account not found.');
          case InvalidSkinImageDataFailure():
            stderr.writeln(
              '❌ The uploaded skin image is not a valid Minecraft skin.',
            );
          case InternalServerFailure():
            stderr.writeln(
              '❌ Minecraft services encountered an internal server error.',
            );
          case ServiceUnavailableFailure(:final retryAfterInSeconds):
            stderr.writeln(
              '❌ Minecraft services are currently unavailable. '
              '${retryAfterInSeconds != null ? 'Please try again after $retryAfterInSeconds seconds.' : 'Please try again later.'}',
            );
          case InvalidDataFormatFailure():
            stderr.writeln(
              '❌ Minecraft services returned malformed or invalid data.',
            );
          case UnexpectedDataStructureFailure():
            stderr.writeln(
              '❌ An unexpected data structure was received from Minecraft services. '
              'Please try updating the application.',
            );
        }
    }
  } finally {
    client.close();
  }
}
