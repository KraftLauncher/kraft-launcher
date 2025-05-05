// This abstraction was made for testing purposes only, allowing to mock the implementation
// or change it without using `TestWidgetsFlutterBinding.ensureInitialized`
// and `CachedNetworkImageProvider.defaultCacheManager`.
abstract class ImageCacheService {
  Future<bool> evictFromCache(String url);
}
