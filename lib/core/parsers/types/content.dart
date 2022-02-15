import '../../common/metadata.dart';

enum ContentBreak { BLOCK_BREAK, LINEBREAK }

enum ContentTextStyle { BOLD, ITALIC, UNDERLINE, LINE, NORMAL }

enum ContentTextSize { s12, s14, s16, s18, s20, s22 }

class ContentUnit<T> {
  T value;

  ContentUnit(this.value);
}

class ContentUnitBreak extends ContentUnit<ContentBreak> {
  ContentUnitBreak(ContentBreak value) : super(value);
}

class ContentUnitImage extends ContentUnit<String> {
  double? width;
  double? height;
  String? prettyImageLink;

  ContentUnitImage(String value, this.width, this.height,
      {this.prettyImageLink})
      : super(value);
}

class ContentUnitGif extends ContentUnit<String> {
  double width;
  double height;
  String? gifUrl;

  ContentUnitGif(String value, this.width, this.height, {this.gifUrl})
      : super(value);
}

class ContentUnitYouTubeVideo extends ContentUnit<String> {
  OEmbedMetadata? metadata;

  ContentUnitYouTubeVideo(String id) : super(id);

  Future<OEmbedMetadata> loadMetadata() {
    return OEmbedMetadata.loadYouTube(value).then((value) {
      metadata = value;
      return value;
    });
  }
}

class ContentUnitCoubVideo extends ContentUnit<String> {
  OEmbedMetadata? metadata;

  ContentUnitCoubVideo(String id) : super(id);

  Future<OEmbedMetadata> loadMetadata() {
    return OEmbedMetadata.loadCoub(value).then((value) {
      metadata = value;
      return value;
    });
  }
}

class ContentUnitVimeoVideo extends ContentUnit<String> {
  OEmbedMetadata? metadata;

  ContentUnitVimeoVideo(String id) : super(id);

  Future<OEmbedMetadata> loadMetadata() {
    return OEmbedMetadata.loadVimeo(value).then((value) {
      metadata = value;
      return value;
    });
  }
}

class ContentUnitSoundCloudAudio extends ContentUnit<String> {
  OEmbedMetadata? metadata;

  ContentUnitSoundCloudAudio(String id) : super(id);

  Future<OEmbedMetadata> loadMetadata() {
    return OEmbedMetadata.loadSoundCloud(value).then((value) {
      metadata = value;
      return value;
    });
  }
}

class ContentUnitText extends ContentUnit<String> {
  List<ContentTextStyle> style;
  ContentTextSize size;

  ContentUnitText(String value, {required this.style, required this.size})
      : super(value);
}

class ContentTextInfo {
  final List<ContentTextStyle> style;
  final ContentTextSize size;

  ContentTextInfo(this.style, this.size);
}

class ContentUnitLink extends ContentUnitText {
  String link;

  ContentUnitLink(String value, {style, size, required this.link})
      : super(value, style: style, size: size);
}
