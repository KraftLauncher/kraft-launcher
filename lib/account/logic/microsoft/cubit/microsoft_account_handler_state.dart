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

  /// Not null if [microsoftLoginStatus] is [MicrosoftLoginStatus.loading]
  /// or [microsoftRefreshAccountStatus] is [MicrosoftRefreshAccountStatus.loading].
  final MicrosoftAuthProgress? authProgress;

  /// Not null if [authProgress] is [MicrosoftAuthProgress.waitingForUserLogin].
  final String? authCodeLoginUrl;

  /// The account that was added or modified.
  ///
  /// Not null if [microsoftLoginStatus] is
  /// [MicrosoftLoginStatus.successAccountAdded] or [MicrosoftLoginStatus.successAccountAdded].
  final MinecraftAccount? recentAccount;

  /// Not null if [microsoftLoginStatus] is a failure (e.g., [MicrosoftLoginStatus.failure])
  final AccountManagerException? exception;

  MinecraftAccount get recentAccountOrThrow =>
      requireNotNull(recentAccount, name: 'recentAccount');

  AccountManagerException get exceptionOrThrow =>
      requireNotNull(exception, name: 'accountManagerException');

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
    MicrosoftAuthProgress? authProgress,
    String? authCodeLoginUrl,
    MinecraftAccount? recentAccount,
    AccountManagerException? exception,
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
