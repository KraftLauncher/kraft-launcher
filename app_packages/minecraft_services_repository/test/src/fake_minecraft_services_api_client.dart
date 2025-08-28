@visibleForTesting
library;

import 'package:meta/meta.dart';
import 'package:minecraft_services_client/minecraft_services_client.dart';
import 'package:result/result.dart';

final class FakeMinecraftServicesApiClient
    implements MinecraftServicesApiClient {
  MinecraftApiResult<T> _dummyDefault<T>() =>
      Result.failure(const UnexpectedFailure('dummy'));

  final List<AuthenticateWithXboxCall> _authenticateWithXboxCalls = [];
  List<AuthenticateWithXboxCall> get authenticateWithXboxCalls =>
      List.unmodifiable(_authenticateWithXboxCalls);
  Future<MinecraftApiResult<MinecraftLoginResponse>> Function(
    AuthenticateWithXboxCall call,
  )?
  whenAuthenticateWithXbox;

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
  Future<MinecraftApiResult<MinecraftLoginResponse>> authenticateWithXbox({
    required String xstsToken,
    required String xstsUserHash,
  }) async {
    final call = AuthenticateWithXboxCall(
      xstsToken: xstsToken,
      xstsUserHash: xstsUserHash,
    );
    _authenticateWithXboxCalls.add(call);

    return whenAuthenticateWithXbox?.call(call) ?? _dummyDefault();
  }

  @override
  Future<MinecraftApiResult<MinecraftEntitlementsResponse>> fetchEntitlements({
    required String accessToken,
  }) async {
    final call = FetchEntitlementsCall(accessToken: accessToken);
    _fetchEntitlementsCalls.add(call);

    return whenFetchEntitlements?.call(call) ?? _dummyDefault();
  }

  @override
  Future<MinecraftApiResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  }) async {
    final call = FetchProfileCall(accessToken: accessToken);
    _fetchProfileCalls.add(call);

    return whenFetchProfile?.call(call) ?? _dummyDefault();
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

    return whenUploadSkin?.call(call) ?? _dummyDefault();
  }

  void reset() {
    _authenticateWithXboxCalls.clear();
    _fetchEntitlementsCalls.clear();
    _fetchProfileCalls.clear();
    _uploadSkinCalls.clear();

    whenAuthenticateWithXbox = null;
    whenFetchEntitlements = null;
    whenFetchProfile = null;
    whenUploadSkin = null;
  }
}

@immutable
final class AuthenticateWithXboxCall {
  const AuthenticateWithXboxCall({
    required this.xstsToken,
    required this.xstsUserHash,
  });

  final String xstsToken;
  final String xstsUserHash;
}

@immutable
final class FetchEntitlementsCall {
  const FetchEntitlementsCall({required this.accessToken});

  final String accessToken;
}

@immutable
final class FetchProfileCall {
  const FetchProfileCall({required this.accessToken});

  final String accessToken;
}

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

HttpResponse<T> httpResponseWithDefaults<T>({
  required T body,
  int? statusCode,
  Map<String, String>? headers,
  String? reasonPhrase,
}) => HttpResponse(
  body: body,
  statusCode: statusCode ?? 200,
  headers: headers ?? {},
  reasonPhrase: reasonPhrase,
);
