import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/common/clipboard.dart';
import '../../core/common/menu.dart';
import '../../core/common/metadata.dart';
import '../../core/common/pair.dart';
import '../../core/common/retry-network-image.dart';
import '../../core/common/save-file.dart';
import '../../core/parsers/types/module.dart';
import '../../core/widgets/safe-image.dart';
import '../../variables.dart';
import '../common/open.dart';
import '../extensions/coub/player.dart';
import '../extensions/soundcloud/player.dart';
import '../extensions/video/player.dart';
import '../extensions/vimeo/player.dart';
import '../extensions/youtube/player.dart';

class AppContentLoader {
  final List<ContentUnit> content;
  final void Function(List<Pair<double, Size>>)? onLoad;

  AppContentLoader({
    required this.content,
    this.onLoad,
  });

  List<Future<OEmbedMetadata>?> _futures = [];
  List<AppNetworkImageWithRetry> _images = [];
  List<AppNetworkImageWithRetry> _imagesForGallery = [];
  late List<ContentUnitImage> _undefinedSizeImages;
  int _undefinedSizeImagesCount = 0;

  late List<Future<OEmbedMetadata>> _filteredFutures;

  bool _initialized = false;

  List<Future<OEmbedMetadata>?> get futures => _futures;

  List<AppNetworkImageWithRetry> get images => _images;

  List<AppNetworkImageWithRetry> get imagesForGallery => _imagesForGallery;

  init() {
    if (!_initialized) {
      _initialized = true;
      _initialize();
    }
  }

  destroy() {
    if (_initialized) {
      _initialized = false;
      [..._images, ..._imagesForGallery].forEach((it) {
        it.cancel();
      });
    }
  }

  _onLoad(List<Pair<double, Size>> arg) {
    if (onLoad != null) {
      onLoad!(arg);
    }
  }

  _initialize() {
    _images = [];
    _futures = [];
    _undefinedSizeImagesCount = 0;
    _undefinedSizeImages = [];

    for (final entry in content) {
      if (entry is ContentUnitImage) {
        final imageProvider = AppNetworkImageWithRetry(
          entry.value,
          headers: Headers.reactorHeaders,
        );

        if (entry.width == null || entry.height == null) {
          _undefinedSizeImages.add(entry);
          _undefinedSizeImagesCount++;
        }

        _images.add(imageProvider);
      } else {
        if (entry is ContentUnitYouTubeVideo) {
          final futureMetadata =
              entry.metadata == null ? entry.loadMetadata() : null;
          _futures.add(futureMetadata);
        } else if (entry is ContentUnitCoubVideo) {
          final futureMetadata =
              entry.metadata == null ? entry.loadMetadata() : null;
          _futures.add(futureMetadata);
        } else if (entry is ContentUnitVimeoVideo) {
          final futureMetadata =
              entry.metadata == null ? entry.loadMetadata() : null;
          _futures.add(futureMetadata);
        }
      }
    }

    _filteredFutures = [
      for (var i in _futures)
        if (i != null) i
    ];

    if (_undefinedSizeImages.isEmpty) {
      if (_filteredFutures.isNotEmpty) {
        Future.wait(_filteredFutures).then(((value) => _onLoad(
              value
                  .map((e) => Pair(
                        16.0 / 9.0,
                        Size(e.width!.toDouble(), e.height!.toDouble()),
                      ))
                  .toList(),
            )));
      } else {
        _onLoad([]);
      }
    }

    _imagesForGallery = List.from(_images);
  }

  bool onImageInfo(ImageInfo imageInfo, ContentUnitImage image) {
    if (_undefinedSizeImages.isNotEmpty &&
        _undefinedSizeImages.contains(image)) {
      image.height = imageInfo.image.height.toDouble();
      image.width = imageInfo.image.width.toDouble();
      _undefinedSizeImagesCount -= 1;
      if (_undefinedSizeImagesCount == 0) {
        final imageSizes = _undefinedSizeImages
            .map((e) => Pair(9.0 / 16.0, Size(e.width!, e.height!)))
            .toList();
        if (_filteredFutures.isNotEmpty) {
          Future.wait(_filteredFutures).then((value) {
            _onLoad([
              ...value.map((e) => Pair(
                    16.0 / 9.0,
                    Size(e.width!.toDouble(), e.height!.toDouble()),
                  )),
              ...imageSizes
            ]);
          });
        } else {
          _onLoad(imageSizes);
        }
      }
      return true;
    }
    return false;
  }

  fillGalleryImage(index) {
    if (index != null) {
      List<ContentUnitImage> images = content
          .where((element) => element is ContentUnitImage)
          .toList()
          .cast();
      if (images[index].prettyImageLink != null &&
          _imagesForGallery[index].url != images[index].prettyImageLink) {
        _imagesForGallery[index] = AppNetworkImageWithRetry(
          images[index].prettyImageLink!,
          headers: Headers.reactorHeaders,
        );
      }
    }
  }
}

class AppContent extends StatefulWidget {
  final bool noHorizontalPadding;
  final List<Widget>? children;
  final AppContentLoader loader;

  AppContent({
    Key? key,
    required this.loader,
    this.noHorizontalPadding = false,
    this.children,
  }) : super(key: key);

  @override
  _AppContentState createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  static final _defaultPadding =
      EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0);

  @override
  void initState() {
    widget.loader.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> newChildren = [];

    List<ContentUnitText> textStack = [];
    var dPadding = widget.noHorizontalPadding
        ? _defaultPadding.copyWith(left: 0, right: 0)
        : _defaultPadding;

    int imagesIndex = 0;
    int futuresIndex = 0;

    for (final entry in widget.loader.content) {
      if (entry is ContentUnitText) {
        textStack.add(entry);
      } else if (textStack.isNotEmpty) {
        newChildren.add(Padding(
          child: _textArrayToRichText(context, textStack),
          padding: dPadding,
        ));
        textStack.clear();
      }

      if (widget.loader.content.last == entry && textStack.isEmpty) {
        dPadding = dPadding.copyWith(bottom: 0);
      }

      if (entry is ContentUnitImage) {
        newChildren.add(Container(
          margin: (entry.width ?? 150) >= 150
              ? dPadding.copyWith(left: 0, right: 0)
              : dPadding,
          width: (entry.width ?? 150) < 150 ? entry.width : null,
          child: _buildImage(entry, context, imagesIndex),
        ));
        imagesIndex++;
      }
      if (entry is ContentUnitGif) {
        newChildren.add(Padding(
          padding: dPadding.copyWith(left: 0, right: 0),
          child: _buildGif(entry, context),
        ));
      }
      if (entry is ContentUnitYouTubeVideo) {
        newChildren.add(Padding(
          padding: dPadding.copyWith(left: 0, right: 0),
          child: AppYouTubePlayer(
            videoId: entry.value,
            metadata: entry.metadata,
            futureMetadata: widget.loader.futures[futuresIndex],
          ),
        ));

        futuresIndex++;
      }
      if (entry is ContentUnitCoubVideo) {
        newChildren.add(Padding(
          padding: dPadding.copyWith(left: 0, right: 0),
          child: AppCoubPlayer(
            videoId: entry.value,
            metadata: entry.metadata,
            futureMetadata: widget.loader.futures[futuresIndex],
          ),
        ));

        futuresIndex++;
      }
      if (entry is ContentUnitVimeoVideo) {
        newChildren.add(Padding(
          padding: dPadding.copyWith(left: 0, right: 0),
          child: AppVimeoPlayer(
            videoId: entry.value,
            metadata: entry.metadata,
            futureMetadata: widget.loader.futures[futuresIndex],
          ),
        ));

        futuresIndex++;
      }
      if (entry is ContentUnitSoundCloudAudio) {
        newChildren.add(Padding(
          padding: dPadding.copyWith(left: 0, right: 0),
          child: AppSoundCloudPlayer(
            url: entry.value,
            metadata: entry.metadata,
            futureMetadata:
                entry.metadata == null ? entry.loadMetadata() : null,
          ),
        ));
      }
    }

    if (textStack.isNotEmpty) {
      newChildren.add(Padding(
        child: _textArrayToRichText(context, textStack),
        padding: widget.noHorizontalPadding
            ? dPadding.copyWith(bottom: 0)
            : dPadding,
      ));
      textStack.clear();
    }

    return Wrap(children: <Widget>[...newChildren, ...(widget.children ?? [])]);
  }

  Widget _buildGif(ContentUnitGif entry, BuildContext context) {
    Offset pos = Offset.zero;
    final menu = Menu(context, items: [
      if (entry.gifUrl != null)
        MenuItem(
            text: "Скачать как гиф",
            onSelect: () {
              SaveFile.downloadAndSave(context, entry.gifUrl!);
            }),
      MenuItem(
          text: "Скачать как видео",
          onSelect: () {
            SaveFile.downloadAndSave(context, entry.value);
          }),
    ]);
    return GestureDetector(
      onLongPress: () {
        menu.openUnderTap(pos);
      },
      onTapDown: (TapDownDetails e) {
        pos = e.globalPosition;
      },
      child: AppVideoPlayer(
        key: ObjectKey(entry),
        aspectRatio: entry.width / entry.height,
        url: entry.value,
      ),
    );
  }

  Widget _buildImage(ContentUnitImage image, BuildContext context, int index) {
    Offset pos = Offset.zero;
    final menu = Menu(context, items: [
      MenuItem(
          text: "Открыть в хорошем качестве",
          onSelect: () {
            widget.loader.fillGalleryImage(index);
            openImage(context, widget.loader.imagesForGallery, index);
          }),
      MenuItem(
          text: "Скачать",
          onSelect: () {
            SaveFile.downloadAndSave(
                context, image.prettyImageLink ?? image.value);
          }),
    ]);
    return GestureDetector(
      onLongPress: () {
        menu.openUnderTap(pos);
      },
      onTapDown: (TapDownDetails e) {
        pos = e.globalPosition;
      },
      onTap: () {
        openImage(context, widget.loader.imagesForGallery, index);
      },
      child: AspectRatio(
        aspectRatio: (image.width != null && image.height != null)
            ? image.width! / image.height!
            : 9.0 / 16.0,
        child: AppSafeImage(
          imageProvider: widget.loader.images[index],
          onInfo: (e) {
            if (widget.loader.onImageInfo(e, image)) {
              if (mounted) setState(() {});
            }
          },
        ),
      ),
    );
  }

  Widget _textArrayToRichText(
      BuildContext context, List<ContentUnitText> list) {
    List<InlineSpan> result = [];
    for (final text in list) {
      double fontSize = 0;

      switch (text.size) {
        case ContentTextSize.s22:
          fontSize = 24;
          break;
        case ContentTextSize.s20:
          fontSize = 22;
          break;
        case ContentTextSize.s18:
          fontSize = 20;
          break;
        case ContentTextSize.s16:
          fontSize = 18;
          break;
        case ContentTextSize.s14:
          fontSize = 16;
          break;
        case ContentTextSize.s12:
          fontSize = 14;
          break;
      }

      TapGestureRecognizer? recognizer;
      if (text is ContentUnitLink) {
        Timer? timer;
        final menu = Menu(context, items: [
          MenuItem(
            text: "Скопировать",
            onSelect: () {
              ClipboardHelper.setClipboardData(context, text.link);
            },
          )
        ]);
        recognizer = TapGestureRecognizer()
          ..onTapDown = (e) {
            timer = Timer(Duration(milliseconds: 350), () {
              menu.openUnderTap(e.globalPosition);
            });
          }
          ..onTapUp = (_) {
            if (timer?.isActive == true) {
              timer!.cancel();
              goToLinkOrOpen(context, text.link!);
            }
          };
      }

      TextDecoration decoration = TextDecoration.none;

      if (text.style.contains(ContentTextStyle.UNDERLINE) &&
          text.style.contains(ContentTextStyle.LINE)) {
        decoration = TextDecoration.combine(
            [TextDecoration.underline, TextDecoration.lineThrough]);
      } else if (text.style.contains(ContentTextStyle.UNDERLINE)) {
        decoration = TextDecoration.underline;
      } else if (text.style.contains(ContentTextStyle.LINE)) {
        decoration = TextDecoration.lineThrough;
      }

      result.add(TextSpan(
        text: text.value,
        recognizer: recognizer,
        style: TextStyle(
          height: 1.4,
          fontSize: fontSize,
          fontWeight: text.style.contains(ContentTextStyle.BOLD)
              ? FontWeight.w500
              : FontWeight.normal,
          fontStyle: text.style.contains(ContentTextStyle.ITALIC)
              ? FontStyle.italic
              : FontStyle.normal,
          decoration: decoration,
        ),
      ));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SelectableText.rich(
        TextSpan(
          text: '',
          style: DefaultTextStyle.of(context).style,
          children: result,
        ),
        scrollPhysics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}
