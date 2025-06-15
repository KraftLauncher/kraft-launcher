import 'package:meta/meta.dart';

import '../../auth_flows/auth_code/microsoft_auth_code_flow.dart';
import '../../auth_flows/device_code/microsoft_device_code_flow.dart';
import '../account_refresher/minecraft_account_refresher.dart';
import '../account_resolver/minecraft_account_resolver.dart';

@immutable
sealed class MinecraftFullAuthProgress {
  const MinecraftFullAuthProgress();

  factory MinecraftFullAuthProgress.authCodeProgress(
    MicrosoftAuthCodeProgress progress,
  ) => MinecraftFullAuthCodeProgress(progress);

  factory MinecraftFullAuthProgress.deviceCode(
    MicrosoftDeviceCodeProgress progress,
  ) => MinecraftFullDeviceCodeProgress(progress);

  factory MinecraftFullAuthProgress.resolveAccount(
    ResolveMinecraftAccountProgress progress,
  ) => MinecraftFullResolveAccountProgress(progress);

  factory MinecraftFullAuthProgress.refresh(
    RefreshMinecraftAccountProgress progress,
  ) => MinecraftFullRefreshAccountProgress(progress);

  MinecraftFullAuthCodeProgress? get authCodeProgress =>
      this is MinecraftFullAuthCodeProgress
          ? this as MinecraftFullAuthCodeProgress
          : null;

  MinecraftFullDeviceCodeProgress? get deviceCodeProgress =>
      this is MinecraftFullDeviceCodeProgress
          ? this as MinecraftFullDeviceCodeProgress
          : null;
}

final class MinecraftFullAuthCodeProgress extends MinecraftFullAuthProgress {
  const MinecraftFullAuthCodeProgress(this.progress);

  final MicrosoftAuthCodeProgress progress;
}

final class MinecraftFullDeviceCodeProgress extends MinecraftFullAuthProgress {
  const MinecraftFullDeviceCodeProgress(this.progress);

  final MicrosoftDeviceCodeProgress progress;
}

final class MinecraftFullResolveAccountProgress
    extends MinecraftFullAuthProgress {
  const MinecraftFullResolveAccountProgress(this.progress);

  final ResolveMinecraftAccountProgress progress;
}

final class MinecraftFullRefreshAccountProgress
    extends MinecraftFullAuthProgress {
  const MinecraftFullRefreshAccountProgress(this.refresh);

  final RefreshMinecraftAccountProgress refresh;
}
