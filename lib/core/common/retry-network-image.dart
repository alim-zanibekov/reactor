import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:path_provider/path_provider.dart';

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

  @override
  Future<bool> evict(
      {ImageCache cache,
      ImageConfiguration configuration = ImageConfiguration.empty}) async {
    return DiskCache().evict(this.url.hashCode.toString());
  }

  existInCache() async {
    final parent = cacheRule.storeDirectory == StoreDirectoryType.temporary
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();

    return File('${parent.path}/imagecache/${this.url.hashCode}').exists();
  }

  static init() {
    if (_diskCache == null) {
      _diskCache = DiskCache();
      _diskCache.evict(null).then((_) => _diskCache.maxSizeBytes = 200 << 20);
    }
  }
}
