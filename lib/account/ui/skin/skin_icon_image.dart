import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../common/ui/utils/build_context_ext.dart';
import '../../../common/ui/widgets/image_error_builder.dart';
import '../../data/launcher_minecraft_account/minecraft_account.dart';
import '../../logic/minecraft_skin_ext.dart';

class SkinIconImage extends StatelessWidget {
  const SkinIconImage({
    super.key,
    required this.account,
    required this.useCircleAvatar,
  });

  final MinecraftAccount? account;
  final bool useCircleAvatar;

  @override
  Widget build(BuildContext context) => () {
    final account = this.account;
    if (account == null) {
      return const Icon(Icons.person);
    }
    if (account.isMicrosoft) {
      final imageUrl = account.headSkinImageUrl;
      if (useCircleAvatar) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: CachedNetworkImageProvider(imageUrl),
        );
      }
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 32,
        height: 32,
        errorWidget: commonCachedNetworkImageErrorBuilder(),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: context.theme.colorScheme.inversePrimary,
      child: Text(account.username[0].toUpperCase()),
    );
  }();
}
