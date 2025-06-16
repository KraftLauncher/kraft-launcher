import 'package:kraft_launcher/account/data/microsoft_auth_api/microsoft_auth_api.dart';

import '../../../common/test_constants.dart';

MicrosoftOAuthTokenResponse dummyMicrosoftOAuthTokenResponse =
    const MicrosoftOAuthTokenResponse(
      accessToken: TestConstants.anyString,
      expiresIn: TestConstants.anyInt,
      refreshToken: TestConstants.anyString,
    );

XboxLiveAuthTokenResponse dummyXboxLiveAuthTokenResponse =
    const XboxLiveAuthTokenResponse(
      userHash: TestConstants.anyString,
      xboxToken: TestConstants.anyString,
    );
