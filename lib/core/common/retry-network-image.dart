import 'package:advanced_image/cache.dart';
import 'package:advanced_image/provider.dart';
import 'package:advanced_image/src/provider/_advanced_network_image_io.dart'
    as io;
import 'package:flutter/widgets.dart';

class AppNetworkImageWithRetry extends io.AdvancedNetworkImage {
  static final RetryOptions _retryOptions = const RetryOptions(maxAttempts: 3);
  static final CacheManager _cacheManager =
      CacheManager(config: CacheConfig(maxBytes: 200 << 20));

  AppNetworkImageWithRetry(String url, {Map<String, String> headers})
      : super(url,
            headers: headers,
            retryOptions: _retryOptions,
            cacheManager: _cacheManager);

  @override
  Future<bool> evict(
      {ImageCache cache,
      ImageConfiguration configuration = ImageConfiguration.empty}) async {
    await _cacheManager.evict(this.url.hashCode.toString());
    return super.evict(cache: null, configuration: configuration);
  }

  existInCache() async {
    return _cacheManager.has(this.url.hashCode.toString());
  }

  loadFromDiskCache() {
    return _cacheManager.get(this.url.hashCode.toString());
  }

  static isUrlExistInCache(String url) async {
    return _cacheManager.has(url.hashCode.toString());
  }
}
