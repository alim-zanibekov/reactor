import 'package:flutter_advanced_networkimage/provider.dart';

class AppNetworkImageWithRetry extends AdvancedNetworkImage {
  AppNetworkImageWithRetry(String url, {Map<String, String> headers})
      : super(
          url,
          header: headers,
          retryLimit: 3,
          useDiskCache: true,
          timeoutDuration: const Duration(minutes: 1),
          cacheRule: CacheRule(maxAge: const Duration(days: 7)),
        );

  static DiskCache _diskCache;

  static init() {
    if (_diskCache == null) {
      _diskCache = DiskCache();
      _diskCache.evict(null).then((_) => _diskCache.maxSizeBytes = 200 << 20);
    }
  }
}
