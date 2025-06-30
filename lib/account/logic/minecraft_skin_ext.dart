import 'package:kraft_launcher/account/logic/launcher_minecraft_account/minecraft_account.dart';

extension MinecraftSkinExt on MinecraftAccount {
  static const _steveUserId = 'f498513c-e8c8-3773-be26-ecfc7ed5185d';

  String get _idOfSkinOwner => isMicrosoft ? id : _steveUserId;

  String get fullSkinImageUrl {
    return 'https://api.mineatar.io/body/full/$_idOfSkinOwner?scale=8&overlay=true${_appendSkinIdQueryParam()}';
  }

  String get headSkinImageUrl {
    return 'https://api.mineatar.io/face/$_idOfSkinOwner?overlay=true${_appendSkinIdQueryParam()}';
  }

  // Adds the skin id for caching purposes, based on the active skin's ID.
  // This is not required or supported by the API and it will be ignored.
  String _appendSkinIdQueryParam() =>
      isMicrosoft
          ? (activeSkin != null ? '&skinId=${activeSkin!.id}' : '')
          : '';
}
