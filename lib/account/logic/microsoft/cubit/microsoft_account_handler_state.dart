part of 'microsoft_account_handler_cubit.dart';

enum MicrosoftLoginStatus {
  initial,
  loading,
  successAccountAdded,
  // User is trying to login with an account that's already exists.
  successAccountUpdated,
  failure,
  cancelled;

  bool get isSuccess => {
    MicrosoftLoginStatus.successAccountAdded,
    MicrosoftLoginStatus.successAccountUpdated,
  }.contains(this);
}

enum MicrosoftRefreshAccountStatus { initial, loading, success, failure }

// When the login dialog is opened, the device code will be automatically requested.
enum DeviceCodeStatus { idle, requestingCode, polling, expired, declined }

final class MicrosoftAccountHandlerState extends Equatable {
  const MicrosoftAccountHandlerState({
    this.microsoftRefreshAccountStatus = MicrosoftRefreshAccountStatus.initial,
    this.microsoftLoginStatus = MicrosoftLoginStatus.initial,
    this.deviceCodeStatus = DeviceCodeStatus.idle,
    this.requestedDeviceCode,
    this.authProgress,
    this.authCodeLoginUrl,
    this.recentAccount,
    this.exception,
  });

  final MicrosoftLoginStatus microsoftLoginStatus;
  final MicrosoftRefreshAccountStatus microsoftRefreshAccountStatus;
  final DeviceCodeStatus deviceCodeStatus;

  /// Not null if [deviceCodeStatus] is [DeviceCodeStatus.polling].
  final String? requestedDeviceCode;

  String get requireRequestedDeviceCode =>
      requestedDeviceCode ??
      (throw StateError(
        'Expected the user device code to be not null when status is: ${DeviceCodeStatus.polling}. Status: $deviceCodeStatus',
      ));

  /// Not null if [microsoftLoginStatus] is [MicrosoftLoginStatus.loading]
  /// or [microsoftRefreshAccountStatus] is [MicrosoftRefreshAccountStatus.loading].
  final MinecraftFullAuthProgress? authProgress;

  /// Not null if [authProgress] is [MinecraftFullAuthCodeProgress.progress] with [MicrosoftAuthCodeProgress.waitingForUserLogin].
  final String? authCodeLoginUrl;

  String get requireAuthCodeLoginUrl =>
      authCodeLoginUrl ??
      (throw StateError(
        'Expected the auth code login URL to be not null for status: ${MicrosoftAuthCodeProgress.waitingForUserLogin}',
      ));

  /// The account that was added or modified.
  ///
  /// Not null if [microsoftLoginStatus] is
  /// [MicrosoftLoginStatus.successAccountAdded] or [MicrosoftLoginStatus.successAccountAdded].
  final MinecraftAccount? recentAccount;

  MinecraftAccount get requireRecentAccount =>
      recentAccount ??
      (throw StateError(
        'Expected the recent Minecraft account to be not null',
      ));

  /// Not null if [microsoftLoginStatus] is a failure (e.g., [MicrosoftLoginStatus.failure])
  final MinecraftAccountServiceException? exception;

  MinecraftAccountServiceException get exceptionOrThrow =>
      exception ??
      (throw StateError(
        'Expected $MinecraftAccountServiceException to be not null in '
        'case of a failure status. '
        '$MicrosoftLoginStatus: $microsoftLoginStatus'
        '$MicrosoftRefreshAccountStatus: $microsoftRefreshAccountStatus'
        '$DeviceCodeStatus: $deviceCodeStatus',
      ));

  @override
  List<Object?> get props => [
    microsoftLoginStatus,
    microsoftRefreshAccountStatus,
    authProgress,
    requestedDeviceCode,
    deviceCodeStatus,
    authCodeLoginUrl,
    recentAccount,
    exception,
  ];

  MicrosoftAccountHandlerState copyWith({
    MicrosoftLoginStatus? microsoftLoginStatus,
    MicrosoftRefreshAccountStatus? microsoftRefreshAccountStatus,
    DeviceCodeStatus? deviceCodeStatus,
    Wrapped<String?>? requestedDeviceCode,
    MinecraftFullAuthProgress? authProgress,
    String? authCodeLoginUrl,
    MinecraftAccount? recentAccount,
    MinecraftAccountServiceException? exception,
  }) {
    return MicrosoftAccountHandlerState(
      microsoftLoginStatus: microsoftLoginStatus ?? this.microsoftLoginStatus,
      microsoftRefreshAccountStatus:
          microsoftRefreshAccountStatus ?? this.microsoftRefreshAccountStatus,
      deviceCodeStatus: deviceCodeStatus ?? this.deviceCodeStatus,
      requestedDeviceCode:
          requestedDeviceCode != null
              ? requestedDeviceCode.value
              : this.requestedDeviceCode,
      authProgress: authProgress ?? this.authProgress,
      authCodeLoginUrl: authCodeLoginUrl ?? this.authCodeLoginUrl,
      recentAccount: recentAccount ?? this.recentAccount,
      exception: exception ?? this.exception,
    );
  }
}
