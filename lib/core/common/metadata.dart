import 'dart:convert';

import 'package:dio/dio.dart';

class OEmbedMetadata {
  // TODO: check required fields
  String? authorName;
  String? providerName;
  String? authorUrl;
  String? title;
  String? type;
  String? html;
  String? thumbnailUrl;
  String? version;
  String? providerUrl;

  int? thumbnailHeight;
  int? thumbnailWidth;
  int? width;
  int? height;

  OEmbedMetadata({
    this.authorName,
    this.providerName,
    this.authorUrl,
    this.title,
    this.type,
    this.html,
    this.thumbnailUrl,
    this.version,
    this.providerUrl,
    this.thumbnailHeight,
    this.thumbnailWidth,
    this.width,
    this.height,
  });

  static Future<OEmbedMetadata> loadYouTube(String videoId) async {
    final dynamic result = await Dio().get(
        'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json');
    return _load(result.data);
  }

  static Future<OEmbedMetadata> loadCoub(String videoId) async {
    final dynamic result = await Dio().get(
        'http://coub.com/api/oembed.json?url=http://coub.com/view/$videoId');
    return _load(result.data);
  }

  static Future<OEmbedMetadata> loadVimeo(String videoId) async {
    final dynamic result = await Dio().get(
        'https://vimeo.com/api/oembed.json?url=https://vimeo.com/video/$videoId');
    return _load(result.data);
  }

  static Future<OEmbedMetadata> loadSoundCloud(String url) async {
    final dynamic result = await Dio().get(
        'https://soundcloud.com/oembed?format=json&url=${Uri.encodeQueryComponent(url)}');
    return _load(result.data);
  }

  static _load(dynamic _metadata) {
    Map<String, dynamic>? metadata;
    if (_metadata is Map<String, dynamic>) {
      metadata = _metadata;
    } else if (_metadata is String) {
      metadata = json.decode(_metadata);
    }
    return metadata != null
        ? OEmbedMetadata(
            authorName: metadata['author_name'],
            providerName: metadata['provider_name'],
            width: toInt(metadata['width']),
            authorUrl: metadata['author_url'],
            height: toInt(metadata['height']),
            title: metadata['title'],
            type: metadata['type'],
            version: metadata['version'].toString(),
            thumbnailWidth: toInt(metadata['thumbnail_width']),
            providerUrl: metadata['provider_url'],
            thumbnailHeight: toInt(metadata['thumbnail_height']),
            html: metadata['html'],
            thumbnailUrl: metadata['thumbnail_url'],
          )
        : null;
  }

  static int? toInt(dynamic i) => i is int ? i : int.tryParse(i ?? '');
}
