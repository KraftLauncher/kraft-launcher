@visibleForTesting
library;

import 'package:meta/meta.dart';
import 'package:minecraft_services_client/minecraft_services_client.dart';
import 'package:result/result.dart';
export 'package:api_client/test.dart' show dummyHttpResponse;

@visibleForTesting
final class FakeMinecraftServicesApiClient
    implements MinecraftServicesApiClient {
  MinecraftApiResult<T> _dummyDefaultResult<T>() =>
      Result.failure(const UnexpectedFailure('dummy'));

  final List<LoginWithXboxCall> _loginWithXboxCalls = [];
  List<LoginWithXboxCall> get loginWithXboxCalls =>
      List.unmodifiable(_loginWithXboxCalls);
  Future<MinecraftApiResult<MinecraftLoginResponse>> Function(
    LoginWithXboxCall call,
  )?
  whenLoginWithXbox;

  final List<FetchEntitlementsCall> _fetchEntitlementsCalls = [];
  List<FetchEntitlementsCall> get fetchEntitlementsCalls =>
      List.unmodifiable(_fetchEntitlementsCalls);
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> Function(
    FetchEntitlementsCall call,
  )?
  whenFetchEntitlements;

  final List<FetchProfileCall> _fetchProfileCalls = [];
  List<FetchProfileCall> get fetchProfileCalls =>
      List.unmodifiable(_fetchProfileCalls);
  Future<MinecraftApiResult<MinecraftProfileResponse>> Function(
    FetchProfileCall call,
  )?
  whenFetchProfile;

  final List<UploadSkinCall> _uploadSkinCalls = [];
  List<UploadSkinCall> get uploadSkinCalls =>
      List.unmodifiable(_uploadSkinCalls);
  Future<MinecraftApiResult<MinecraftProfileResponse>> Function(
    UploadSkinCall call,
  )?
  whenUploadSkin;

  @override
  Future<MinecraftApiResult<MinecraftLoginResponse>> loginWithXbox({
    required String xstsAccessToken,
    required String xstsUserHash,
  }) async {
    final call = LoginWithXboxCall(
      xstsAccessToken: xstsAccessToken,
      xstsUserHash: xstsUserHash,
    );
    _loginWithXboxCalls.add(call);

    return whenLoginWithXbox?.call(call) ?? _dummyDefaultResult();
  }

  @override
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> fetchEntitlements({
    required String accessToken,
  }) async {
    final call = FetchEntitlementsCall(accessToken: accessToken);
    _fetchEntitlementsCalls.add(call);

    return whenFetchEntitlements?.call(call) ?? _dummyDefaultResult();
  }

  @override
  Future<MinecraftApiResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  }) async {
    final call = FetchProfileCall(accessToken: accessToken);
    _fetchProfileCalls.add(call);

    return whenFetchProfile?.call(call) ?? _dummyDefaultResult();
  }

  @override
  Future<MinecraftApiResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required MultipartFile skinFile,
    required MinecraftSkinVariant variant,
  }) async {
    final call = UploadSkinCall(
      accessToken: accessToken,
      skinFile: skinFile,
      variant: variant,
    );
    _uploadSkinCalls.add(call);

    return whenUploadSkin?.call(call) ?? _dummyDefaultResult();
  }

  void reset() {
    _loginWithXboxCalls.clear();
    _fetchEntitlementsCalls.clear();
    _fetchProfileCalls.clear();
    _uploadSkinCalls.clear();

    whenLoginWithXbox = null;
    whenFetchEntitlements = null;
    whenFetchProfile = null;
    whenUploadSkin = null;
  }
}

@visibleForTesting
@immutable
final class LoginWithXboxCall {
  const LoginWithXboxCall({
    required this.xstsAccessToken,
    required this.xstsUserHash,
  });

  final String xstsAccessToken;
  final String xstsUserHash;
}

@visibleForTesting
@immutable
final class FetchEntitlementsCall {
  const FetchEntitlementsCall({required this.accessToken});

  final String accessToken;
}

@visibleForTesting
@immutable
final class FetchProfileCall {
  const FetchProfileCall({required this.accessToken});

  final String accessToken;
}

@visibleForTesting
@immutable
final class UploadSkinCall {
  const UploadSkinCall({
    required this.accessToken,
    required this.skinFile,
    required this.variant,
  });

  final String accessToken;
  final MultipartFile skinFile;
  final MinecraftSkinVariant variant;
}
