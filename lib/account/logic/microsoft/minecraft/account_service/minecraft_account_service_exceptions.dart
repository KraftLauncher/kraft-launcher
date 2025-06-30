import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
import 'package:kraft_launcher/account/data/minecraft_account_api/minecraft_account_api_exceptions.dart'
    as minecraft_account_api_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/auth_flows/auth_code/microsoft_auth_code_flow_exceptions.dart'
    as microsoft_auth_code_flow_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/minecraft_account_refresher_exceptions.dart'
    as minecraft_account_refresher_exceptions;
import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_resolver/minecraft_account_resolver_exceptions.dart'
    as minecraft_account_resolver_exceptions;
import 'package:meta/meta.dart';

@immutable
sealed class MinecraftAccountServiceException implements Exception {
  const MinecraftAccountServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class MicrosoftAuthApiException extends MinecraftAccountServiceException {
  MicrosoftAuthApiException(this.exception) : super(exception.message);

  final microsoft_auth_api_exceptions.MicrosoftAuthApiException exception;
}

final class MinecraftAccountApiException
    extends MinecraftAccountServiceException {
  MinecraftAccountApiException(this.exception) : super(exception.message);

  final minecraft_account_api_exceptions.MinecraftAccountApiException exception;
}

final class MicrosoftAuthCodeFlowException
    extends MinecraftAccountServiceException {
  MicrosoftAuthCodeFlowException(this.exception) : super(exception.message);

  final microsoft_auth_code_flow_exceptions.MicrosoftAuthCodeFlowException
  exception;
}

final class MinecraftAccountResolverException
    extends MinecraftAccountServiceException {
  MinecraftAccountResolverException(this.exception) : super(exception.message);

  final minecraft_account_resolver_exceptions.MinecraftAccountResolverException
  exception;
}

final class MinecraftAccountRefresherException
    extends MinecraftAccountServiceException {
  MinecraftAccountRefresherException(this.exception) : super(exception.message);

  final minecraft_account_refresher_exceptions.MinecraftAccountRefresherException
  exception;
}
