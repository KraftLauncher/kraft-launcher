import 'package:clock/clock.dart';

import '../../../common/constants/constants.dart';

// NOTE: The Microsoft API doesn't provide the expiration date for the refresh token,
// it's 90 days according to https://learn.microsoft.com/en-us/entra/identity-platform/refresh-tokens#token-lifetime.
// The app will always need to handle the case where it's expired or access is revoked when sending the request.
DateTime microsoftRefreshTokenExpiresAt() => clock.now().add(
  const Duration(days: MicrosoftConstants.refreshTokenExpiresInDays),
);
