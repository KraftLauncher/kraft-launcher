import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;

import 'package:kraft_launcher/account/logic/microsoft/minecraft/account_refresher/image_cache_service/image_cache_service.dart';

// TODO: Part of the data layer, move it away from logic

class DefaultImageCacheService implements ImageCacheService {
  DefaultImageCacheService({this.cacheManager});

  final BaseCacheManager? cacheManager;

  @override
  Future<bool> evictFromCache(String url) =>
      CachedNetworkImage.evictFromCache(url, cacheManager: cacheManager);
}
