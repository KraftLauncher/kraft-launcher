import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';

import '../../../common/test_constants.dart';

// TODO: Search for all usages of MicrosoftOAuthTokenResponse and use this when ever possible
MicrosoftOAuthTokenResponse dummyMicrosoftOAuthTokenResponse =
    const MicrosoftOAuthTokenResponse(
      accessToken: TestConstants.anyString,
      expiresIn: TestConstants.anyInt,
      refreshToken: TestConstants.anyString,
    );

// TODO: Search for all usages of XboxLiveAuthTokenResponse and use this when ever possible
XboxLiveAuthTokenResponse dummyXboxLiveAuthTokenResponse =
    const XboxLiveAuthTokenResponse(
      userHash: TestConstants.anyString,
      xboxToken: TestConstants.anyString,
    );
