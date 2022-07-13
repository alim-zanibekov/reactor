import 'dart:io';
import 'dart:typed_data';

import 'package:advanced_image/cache.dart';
import 'package:advanced_image/provider.dart';
// ignore: implementation_imports
import 'package:advanced_image/src/provider/_advanced_network_image_io.dart'
    if (dart.library.html) 'package:advanced_image/src/provider/_advanced_network_image_web.dart'
    as io;
import 'package:flutter/widgets.dart';

import '../http/dio-instance.dart';
import '../parsers/utils.dart';

class AppNetworkImageWithRetry extends io.AdvancedNetworkImage {
  static final RetryOptions _retryOptions = const RetryOptions(maxAttempts: 3);
  static final CacheManager _cacheManager =
      CacheManager(config: CacheConfig(maxBytes: 200 << 20));
  static final _dio = getDioInstance();

  AppNetworkImageWithRetry(String url, {Map<String, String>? headers})
      : super(Utils.fulfillUrl(url),
            headers: headers,
            retryOptions: _retryOptions,
            cacheManager: _cacheManager,
            dio: _dio);

  @override
  Future<bool> evict(
      {ImageCache? cache,
      ImageConfiguration configuration = ImageConfiguration.empty}) async {
    await _cacheManager.evict(this.url.hashCode.toString());
    return super.evict(cache: null, configuration: configuration);
  }

  Future<bool> existInCache() async {
    return _cacheManager.has(this.url.hashCode.toString());
  }

  Future<Uint8List?> loadContentsFromDiskCache() {
    return _cacheManager.get(this.url.hashCode.toString());
  }

  Future<File?> loadFromDiskCache() {
    return _cacheManager.getFile(this.url.hashCode.toString());
  }

  static isUrlExistInCache(String url) async {
    return _cacheManager.has(url.hashCode.toString());
  }
}
