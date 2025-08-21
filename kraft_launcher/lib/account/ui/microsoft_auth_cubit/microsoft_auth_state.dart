part of 'microsoft_auth_cubit.dart';

enum MicrosoftLoginStatus {
  initial,

  /// Login process is currently ongoing.
  loading,

  /// Login succeeded with a newly added account (account did not exist before).
  successAddedNew,

  /// Login succeeded by refreshing an existing account (account was already present).
  successRefreshedExisting,

  /// Login attempt failed due to an error.
  failure,

  /// Login process was cancelled by the user.
  cancelled;

  /// Returns `true` if the login was successful, either by adding a new account
  /// or refreshing an existing one.
  bool get isSuccess => {
    MicrosoftLoginStatus.successAddedNew,
    MicrosoftLoginStatus.successRefreshedExisting,
  }.contains(this);
}

enum MicrosoftRefreshAccountStatus { initial, loading, success, failure }

// When the login dialog is opened, the device code will be automatically requested.
enum MicrosoftDeviceCodeStatus {
  idle,
  requestingCode,
  polling,
  expired,
  declined,
}

enum MicrosoftAuthFlow { authCode, deviceCode }

final class MicrosoftAuthState extends Equatable {
  const MicrosoftAuthState({
    this.refreshStatus = MicrosoftRefreshAccountStatus.initial,
    this.loginStatus = MicrosoftLoginStatus.initial,
    this.deviceCodeStatus = MicrosoftDeviceCodeStatus.idle,
    this.requestedDeviceCode,
    this.loginProgress,
    this.refreshAccountProgress,
    this.authCodeLoginUrl,
    this.recentAccount,
    this.exception,
    this.authFlow,
    this.supportsSecureStorage,
  });

  final MicrosoftLoginStatus loginStatus;
  final MicrosoftRefreshAccountStatus refreshStatus;
  final MicrosoftDeviceCodeStatus deviceCodeStatus;

  /// Not null if [deviceCodeStatus] is [MicrosoftDeviceCodeStatus.polling].
  final String? requestedDeviceCode;

  String get requestedDeviceCodeOrThrow =>
      requestedDeviceCode ??
      (throw StateError(
        'Expected the user device code to be not null when status is: ${MicrosoftDeviceCodeStatus.polling}. Status: $deviceCodeStatus',
      ));

  /// Not null if [loginStatus] is [MicrosoftLoginStatus.loading] and [authFlow]
  /// is either [MicrosoftAuthFlow.authCode] or [MicrosoftAuthFlow.deviceCode].
  final MinecraftAuthProgress? loginProgress;

  /// Not null if [refreshStatus] is [MicrosoftRefreshAccountStatus.loading].
  final MinecraftAuthProgress? refreshAccountProgress;

  /// Not null if [authCodeProgress] is [MicrosoftAuthCodeProgress.waitingForUserLogin].
  final String? authCodeLoginUrl;

  String get authCodeLoginUrlOrThrow =>
      authCodeLoginUrl ??
      (throw StateError(
        'Expected the auth code login URL to be not null for status: ${MicrosoftAuthCodeProgress.waitingForUserLogin}',
      ));

  /// The account that was added or modified.
  ///
  /// Not null if [loginStatus] is
  /// [MicrosoftLoginStatus.successAddedNew] or [MicrosoftLoginStatus.successAddedNew].
  final MinecraftAccount? recentAccount;

  MinecraftAccount get recentAccountOrThrow =>
      recentAccount ??
      (throw StateError(
        'Expected the recent Minecraft account to be not null',
      ));

  /// Not null if [loginStatus] is [MicrosoftLoginStatus.failure].
  final MinecraftAccountServiceException? exception;

  final MicrosoftAuthFlow? authFlow;

  MinecraftAccountServiceException get exceptionOrThrow =>
      exception ??
      (throw StateError(
        'Expected $MinecraftAccountServiceException to be not null in '
        'case of a failure status. '
        '$MicrosoftLoginStatus: $loginStatus'
        '$MicrosoftRefreshAccountStatus: $refreshStatus'
        '$MicrosoftDeviceCodeStatus: $deviceCodeStatus',
      ));

  final bool? supportsSecureStorage;

  @override
  List<Object?> get props => [
    loginStatus,
    refreshStatus,
    loginProgress,
    refreshAccountProgress,
    requestedDeviceCode,
    deviceCodeStatus,
    authCodeLoginUrl,
    recentAccount,
    exception,
    authFlow,
    supportsSecureStorage,
  ];

  MicrosoftAuthState copyWith({
    MicrosoftLoginStatus? loginStatus,
    MicrosoftRefreshAccountStatus? refreshStatus,
    MicrosoftDeviceCodeStatus? deviceCodeStatus,
    Wrapped<String?>? requestedDeviceCode,
    String? authCodeLoginUrl,
    MinecraftAccount? recentAccount,
    MinecraftAccountServiceException? exception,
    MicrosoftAuthFlow? authFlow,
    bool? supportsSecureStorage,
    MinecraftAuthProgress? loginProgress,
    MinecraftAuthProgress? refreshAccountProgress,
  }) {
    return MicrosoftAuthState(
      loginStatus: loginStatus ?? this.loginStatus,
      refreshStatus: refreshStatus ?? this.refreshStatus,
      deviceCodeStatus: deviceCodeStatus ?? this.deviceCodeStatus,
      requestedDeviceCode: requestedDeviceCode != null
          ? requestedDeviceCode.value
          : this.requestedDeviceCode,
      authCodeLoginUrl: authCodeLoginUrl ?? this.authCodeLoginUrl,
      recentAccount: recentAccount ?? this.recentAccount,
      exception: exception ?? this.exception,
      authFlow: authFlow ?? this.authFlow,
      supportsSecureStorage:
          supportsSecureStorage ?? this.supportsSecureStorage,
      loginProgress: loginProgress ?? this.loginProgress,
      refreshAccountProgress:
          refreshAccountProgress ?? this.refreshAccountProgress,
    );
  }
}
