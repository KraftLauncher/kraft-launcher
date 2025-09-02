@visibleForTesting
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:minecraft_services_repository/minecraft_services_repository.dart';
import 'package:result/result.dart';

@visibleForTesting
final class FakeMinecraftServicesRepository
    implements MinecraftServicesRepository {
  MinecraftServicesResult<T> _dummyDefaultResult<T>() =>
      Result.failure(const UnexpectedFailure('dummy'));

  final List<AuthenticateWithXboxCall> _authenticateWithXboxCalls = [];
  List<AuthenticateWithXboxCall> get authenticateWithXboxCalls =>
      List.unmodifiable(_authenticateWithXboxCalls);
  Future<MinecraftServicesResult<MinecraftLoginResponse>> Function(
    AuthenticateWithXboxCall call,
  )?
  whenAuthenticateWithXbox;

  final List<HasValidMinecraftJavaLicenseCall>
  _hasValidMinecraftJavaLicenseCalls = [];
  List<HasValidMinecraftJavaLicenseCall>
  get hasValidMinecraftJavaLicenseCalls =>
      List.unmodifiable(_hasValidMinecraftJavaLicenseCalls);
  Future<MinecraftServicesResult<bool>> Function(
    HasValidMinecraftJavaLicenseCall call,
  )?
  whenHasValidMinecraftJavaLicense;

  final List<FetchProfileCall> _fetchProfileCalls = [];
  List<FetchProfileCall> get fetchProfileCalls =>
      List.unmodifiable(_fetchProfileCalls);
  Future<MinecraftServicesResult<MinecraftProfileResponse>> Function(
    FetchProfileCall call,
  )?
  whenFetchProfile;

  final List<UploadSkinCall> _uploadSkinCalls = [];
  List<UploadSkinCall> get uploadSkinCalls =>
      List.unmodifiable(_uploadSkinCalls);
  Future<MinecraftServicesResult<MinecraftProfileResponse>> Function(
    UploadSkinCall call,
  )?
  whenUploadSkin;

  @override
  Future<MinecraftServicesResult<MinecraftLoginResponse>> authenticateWithXbox({
    required String xstsAccessToken,
    required String xstsUserHash,
  }) async {
    final call = AuthenticateWithXboxCall(
      xstsAccessToken: xstsAccessToken,
      xstsUserHash: xstsUserHash,
    );
    _authenticateWithXboxCalls.add(call);

    return whenAuthenticateWithXbox?.call(call) ?? _dummyDefaultResult();
  }

  @override
  Future<MinecraftServicesResult<bool>> hasValidMinecraftJavaLicense({
    required String accessToken,
  }) async {
    final call = HasValidMinecraftJavaLicenseCall(accessToken: accessToken);
    _hasValidMinecraftJavaLicenseCalls.add(call);

    return whenHasValidMinecraftJavaLicense?.call(call) ??
        _dummyDefaultResult();
  }

  @override
  Future<MinecraftServicesResult<MinecraftProfileResponse>> fetchProfile({
    required String accessToken,
  }) async {
    final call = FetchProfileCall(accessToken: accessToken);
    _fetchProfileCalls.add(call);

    return whenFetchProfile?.call(call) ?? _dummyDefaultResult();
  }

  @override
  Future<MinecraftServicesResult<MinecraftProfileResponse>> uploadSkin({
    required String accessToken,
    required Uint8List skinBytes,
    required MinecraftSkinVariant variant,
  }) async {
    final call = UploadSkinCall(
      accessToken: accessToken,
      skinBytes: skinBytes,
      variant: variant,
    );
    _uploadSkinCalls.add(call);

    return whenUploadSkin?.call(call) ?? _dummyDefaultResult();
  }

  void reset() {
    _authenticateWithXboxCalls.clear();
    _hasValidMinecraftJavaLicenseCalls.clear();
    _fetchProfileCalls.clear();
    _uploadSkinCalls.clear();

    whenAuthenticateWithXbox = null;
    whenHasValidMinecraftJavaLicense = null;
    whenFetchProfile = null;
    whenUploadSkin = null;
  }

  void verifyZeroInteractions() {
    final checks = <String, List<Object>>{
      'authenticateWithXbox': _authenticateWithXboxCalls,
      'hasValidMinecraftJavaLicense': _hasValidMinecraftJavaLicenseCalls,
      'fetchProfile': _fetchProfileCalls,
      'uploadSkin': _uploadSkinCalls,
    };

    for (final entry in checks.entries) {
      if (entry.value.isNotEmpty) {
        throw StateError(
          'Expected 0 interactions with ${entry.key}() but found ${entry.value.length}',
        );
      }
    }
  }

  void verifyMethodCallCounts({
    int authenticateWithXbox = 0,
    int hasValidMinecraftJavaLicense = 0,
    int fetchProfile = 0,
    int uploadSkin = 0,
  }) {
    final methodCallExpectations = <String, (int, int)>{
      'authenticateWithXbox': (
        authenticateWithXbox,
        authenticateWithXboxCalls.length,
      ),
      'hasValidMinecraftJavaLicense': (
        hasValidMinecraftJavaLicense,
        hasValidMinecraftJavaLicenseCalls.length,
      ),
      'fetchProfile': (fetchProfile, fetchProfileCalls.length),
      'uploadSkin': (uploadSkin, uploadSkinCalls.length),
    };

    for (final entry in methodCallExpectations.entries) {
      final (expectedCalls, actualCalls) = entry.value;
      if (expectedCalls != actualCalls) {
        throw StateError(
          'Expected $expectedCalls interactions with ${entry.key}() but found $actualCalls.',
        );
      }
    }
  }
}

@visibleForTesting
@immutable
final class AuthenticateWithXboxCall {
  const AuthenticateWithXboxCall({
    required this.xstsAccessToken,
    required this.xstsUserHash,
  });

  final String xstsAccessToken;
  final String xstsUserHash;
}

@visibleForTesting
@immutable
final class HasValidMinecraftJavaLicenseCall {
  const HasValidMinecraftJavaLicenseCall({required this.accessToken});

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
    required this.skinBytes,
    required this.variant,
  });

  final String accessToken;
  final Uint8List skinBytes;
  final MinecraftSkinVariant variant;
}
