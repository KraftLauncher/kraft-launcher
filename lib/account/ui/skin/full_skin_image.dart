import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';
import 'package:kraft_launcher/account/logic/minecraft_skin_ext.dart';
import 'package:kraft_launcher/common/ui/widgets/image_error_builder.dart';

class FullSkinImage extends StatelessWidget {
  const FullSkinImage({super.key, required this.account});

  final MinecraftAccount account;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: account.fullSkinImageUrl,
      width: 139,
      height: 312,
      errorWidget: commonCachedNetworkImageErrorBuilder(),
    );
  }
}
