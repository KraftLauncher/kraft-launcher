import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage;
// ignore: depend_on_referenced_packages
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;
import 'package:flutter_test/flutter_test.dart';
import 'package:kraft_launcher/account/data/image_cache_service/default_image_cache_service.dart';
import 'package:kraft_launcher/account/data/image_cache_service/image_cache_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../common/helpers/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockBaseCacheManager mockBaseCacheManager;
  late ImageCacheService imageCacheService;

  setUp(() {
    mockBaseCacheManager = _MockBaseCacheManager();
    imageCacheService = DefaultImageCacheService(
      cacheManager: mockBaseCacheManager,
    );
  });
  test('delegates to $CachedNetworkImage.evict', () async {
    when(() => mockBaseCacheManager.removeFile(any())).thenDoNothing();

    const exampleUrl =
        'https://example.com/image/123/sdadksadklsa.png&id=dsajkdasjkdsa';
    await imageCacheService.evictFromCache(exampleUrl);

    final result = verify(() => mockBaseCacheManager.removeFile(captureAny()));
    result.called(1);

    final capturedKey = result.captured.first as String?;
    expect(capturedKey, exampleUrl);
  });
}

class _MockBaseCacheManager extends Mock implements BaseCacheManager {}
