import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;

import 'image_cache_service.dart';

class DefaultImageCacheService implements ImageCacheService {
  DefaultImageCacheService({this.cacheManager});

  final BaseCacheManager? cacheManager;

  @override
  Future<bool> evictFromCache(String url) =>
      CachedNetworkImage.evictFromCache(url, cacheManager: cacheManager);
}
