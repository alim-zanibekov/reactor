import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

class AppContent extends StatefulWidget {
  final List<ContentUnit> content;
  final void Function(List<Pair<double, Size>>) onLoad;
  final bool noHorizontalPadding;
  final List<Widget> children;

  const AppContent({
    Key key,
    this.content,
    this.onLoad,
    this.noHorizontalPadding = false,
    this.children,
  }) : super(key: key);

  @override
  _AppContentState createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
  static final _defaultPadding =
      EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0);
  List<Future<OEmbedMetadata>> _futures = [];
  List<AppNetworkImageWithRetry> _images = [];
  List<AppNetworkImageWithRetry> _imagesForGallery = [];
  List<ContentUnitImage> _undefinedSizeImages;
  int _undefinedSizeImagesCount;

  List<Future<OEmbedMetadata>> _filteredFutures;

  @override
  void initState() {
    _getFutures();
    super.initState();
  }

  _fillGalleryImage(index) {
    if (index != null) {
      List<ContentUnitImage> images = widget.content
          .where((element) => element is ContentUnitImage)
          .toList()
          .cast();
      if (images[index].prettyImageLink != null &&
          _imagesForGallery[index].url != images[index].prettyImageLink) {
        _imagesForGallery[index] = AppNetworkImageWithRetry(
          images[index].prettyImageLink,
          headers: Headers.reactorHeaders,
        );
      }
    }
  }

  _getFutures() async {
    _images = [];
    _futures = [];
    _undefinedSizeImagesCount = 0;
    _undefinedSizeImages = [];

    for (final entry in widget.content) {
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
      }
      if (entry is ContentUnitYouTubeVideo) {
        final futureMetadata =
            entry.metadata == null ? entry.loadMetadata() : null;
        _futures.add(futureMetadata);
      }
      if (entry is ContentUnitCoubVideo) {
        final futureMetadata =
            entry.metadata == null ? entry.loadMetadata() : null;
        _futures.add(futureMetadata);
      }
      if (entry is ContentUnitVimeoVideo) {
        final futureMetadata =
            entry.metadata == null ? entry.loadMetadata() : null;
        _futures.add(futureMetadata);
      }
    }

    _filteredFutures = _futures.where((element) => element != null).toList();

    if (widget.onLoad != null && _undefinedSizeImages.isEmpty) {
      if (_filteredFutures.isNotEmpty) {
        Future.wait(_filteredFutures).then((value) => widget.onLoad(value
            .map((e) => Pair(
                  16.0 / 9.0,
                  Size(e.width.toDouble(), e.height.toDouble()),
                ))
            .toList()));
      } else {
        widget.onLoad([]);
      }
    }

    _imagesForGallery = List.from(_images);
  }

  void _onImageInfo(ImageInfo imageInfo, ContentUnitImage image) {
    if (_undefinedSizeImages.isNotEmpty &&
        _undefinedSizeImages.contains(image)) {
      image.height = imageInfo.image.height.toDouble();
      image.width = imageInfo.image.width.toDouble();
      if (mounted) setState(() {});
      _undefinedSizeImagesCount -= 1;
      if (_undefinedSizeImagesCount == 0) {
        final imageSizes = _undefinedSizeImages
            .map((e) => Pair(9.0 / 16.0, Size(e.width, e.height)))
            .toList();
        if (_filteredFutures.isNotEmpty) {
          Future.wait(_filteredFutures).then((value) {
            widget.onLoad([
              ...value.map((e) => Pair(
                    16.0 / 9.0,
                    Size(e.width.toDouble(), e.height.toDouble()),
                  )),
              ...imageSizes
            ]);
          });
        } else {
          widget.onLoad(imageSizes);
        }
      }
    }
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

    for (final entry in widget.content) {
      if (entry is ContentUnitText) {
        textStack.add(entry);
      } else if (textStack.isNotEmpty) {
        newChildren.add(Padding(
          child: _textArrayToRichText(context, textStack),
          padding: dPadding,
        ));
        textStack.clear();
      }

      if (widget.content.last == entry && textStack.isEmpty) {
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
            futureMetadata: _futures[futuresIndex],
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
            futureMetadata: _futures[futuresIndex],
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
            futureMetadata: _futures[futuresIndex],
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
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    Offset pos = Offset.zero;
    return GestureDetector(
      onLongPress: () {
        showMenu(
          position: RelativeRect.fromRect(
              pos & Size(40, 40), // smaller rect, the touch area
              Offset.zero & overlay.size // Bigger rect, the entire screen
              ),
          context: context,
          items: [
            if (entry.gifUrl != null)
              PopupMenuItem(
                child: Text("Скачать как гиф"),
                value: 1,
              ),
            PopupMenuItem(
              child: Text("Скачать как видео"),
              value: 2,
            ),
          ],
          elevation: 8.0,
        ).then<void>((dynamic delta) async {
          if (delta != null) {
            final url = (delta == 1) ? entry.gifUrl : entry.value;
            SaveFile.downloadAndSave(context, url);
          }
        });
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
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    Offset pos = Offset.zero;
    return GestureDetector(
      onLongPress: () {
        showMenu(
          position: RelativeRect.fromRect(
            pos & Size(40, 40), // smaller rect, the touch area
            Offset.zero & overlay.size, // Bigger rect, the entire screen
          ),
          context: context,
          items: [
            PopupMenuItem(
              child: Text("Открыть в хорошем качестве"),
              value: 1,
            ),
            PopupMenuItem(
              child: Text("Скачать"),
              value: 2,
            ),
          ],
          elevation: 8.0,
        ).then<void>((dynamic delta) {
          if (delta == 1) {
            _fillGalleryImage(index);
            openImage(context, _imagesForGallery, index);
          } else if (delta == 2) {
            SaveFile.downloadAndSave(
              context,
              image.prettyImageLink ?? image.value,
            );
          }
        });
      },
      onTapDown: (TapDownDetails e) {
        pos = e.globalPosition;
      },
      onTap: () {
        openImage(context, _imagesForGallery, index);
      },
      child: AspectRatio(
        aspectRatio: (image.width != null && image.height != null)
            ? image.width / image.height
            : 9.0 / 16.0,
        child: AppSafeImage(
          imageProvider: _images[index],
          onInfo: (e) => _onImageInfo(e, image),
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

      TapGestureRecognizer recognizer;
      if (text is ContentUnitLink) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => goToLinkOrOpen(context, text.link);
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
      child: RichText(
        text: TextSpan(
          text: '',
          style: DefaultTextStyle
              .of(context)
              .style,
          children: result,
        ),
      ),
    );
  }
}
