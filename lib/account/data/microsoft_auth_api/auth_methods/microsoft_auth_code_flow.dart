import '../../../../common/constants/microsoft_constants.dart';
import '../microsoft_auth_api.dart';

abstract class MicrosoftAuthCodeFlow {
  /// Returns the login URL that the user needs to open to start logging in.
  ///
  /// This doesn't start the redirect server which the API will redirect to
  /// after a successful login.
  ///
  /// Only works on the current machine. Microsoft will redirect the
  /// user to the [MicrosoftConstants.loginRedirectUrl] with a `code` parameter
  /// (e.g., `http://127.0.0.1:48162/?code=M.C515_SN1.2.U.169e8c98-7710-97d2-817e-76740b144f41`).
  /// This code can be passed to [exchangeAuthCodeForTokens] to proceed.
  String userLoginUrlWithAuthCode();

  /// Returns the access and refresh tokens of the Microsoft account
  /// using the [authCode].
  ///
  /// To get this token, the user needs to open the link returned by
  /// [userLoginUrlWithAuthCode] and once the login is successful,
  /// Microsoft will redirect to the redirect URI with the `code` query parameter
  /// (e.g., `http://127.0.0.1:48162/?code=M.C515_SN1.2.U.169e8c98-7710-97d2-817e-76740b144f41`).
  Future<MicrosoftOauthTokenExchangeResponse> exchangeAuthCodeForTokens(
    String authCode,
  );
}
