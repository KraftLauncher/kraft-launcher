import 'package:flutter/material.dart';
import 'package:kraft_launcher/common/constants/constants.dart';
import 'package:kraft_launcher/common/ui/utils/build_context_ext.dart';
import 'package:url_launcher/url_launcher.dart';

class MinecraftJavaEntitlementAbsentDialog extends StatelessWidget {
  const MinecraftJavaEntitlementAbsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.minecraftJavaNotOwnedTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Text(context.loc.minecraftOwnershipRequiredError),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.loc.close),
        ),
        TextButton(
          onPressed: () {
            launchUrl(Uri.parse(MinecraftConstants.redeemMinecraftLink));
            Navigator.pop(context);
          },
          child: Text(context.loc.redeemCode),
        ),
        TextButton(
          onPressed: () {
            launchUrl(Uri.parse(MinecraftConstants.buyMinecraftLink));
            Navigator.pop(context);
          },
          child: Text(context.loc.visitMinecraftStore),
        ),
      ],
    );
  }
}
