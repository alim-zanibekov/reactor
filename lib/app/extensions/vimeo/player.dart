import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/external/error-reporter.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppVimeoPlayer extends StatefulWidget {
  final String? videoId;
  final OEmbedMetadata? metadata;
  final Future<OEmbedMetadata>? futureMetadata;

  AppVimeoPlayer(
      {Key? key, required this.videoId, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppVimeoPlayerState createState() => _AppVimeoPlayerState();
}

class _AppVimeoPlayerState extends State<AppVimeoPlayer>
    with AutomaticKeepAliveClientMixin {
  late String _url;
  OEmbedMetadata? _metadata;
  double _aspectRatio = 16.0 / 9.0;
  bool _webViewShow = false;
  bool _error = false;
  bool _wantKeepAlive = false;

  @override
  void initState() {
    super.initState();
    final metadata = widget.metadata;
    _metadata = metadata;

    if (metadata != null) {
      _aspectRatio = metadata.width / metadata.height;
    } else {
      widget.futureMetadata?.then((value) {
        _metadata = value;
        _aspectRatio = value.width / value.height;
        if (mounted) {
          setState(() {});
        }
      }).catchError((dynamic error, StackTrace stackTrace) {
        ErrorReporter.reportError(error, stackTrace);
      });
    }
    _url = 'https://player.vimeo.com/video/${widget.videoId}';
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  Widget getVideo(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(_url)),
          initialOptions: inAppWebViewDefaultOptions(),
          onLoadStop: (controller, _) {
            controller.injectCSSCode(
                source: '.vp-sidedock { display: none!important;}');
            controller.evaluateJavascript(
                source: 'document.querySelector("button.play").click()');
          },
          shouldOverrideUrlLoading: (controller, request) async {
            canLaunch(request.request.url.toString()).then((value) => value
                ? launch(request.request.url.toString())
                : Future.value(false));

            return NavigationActionPolicy.CANCEL;
          },
          onEnterFullscreen: (_) {
            _wantKeepAlive = true;
            updateKeepAlive();
          },
          onExitFullscreen: (_) {
            _wantKeepAlive = false;
            updateKeepAlive();
          },
          onLoadError: (controller, url, err1, err2) {
            _error = true;
            if (mounted) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_error) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: AppOnErrorReload(
          text: 'Произошла ошибка при загруке',
          onReloadPressed: () {
            setState(() {
              _webViewShow = false;
              _error = false;
            });
          },
        ),
      );
    }
    if (_webViewShow) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: getVideo(context),
      );
    }

    return VideoThumbnail(
      imageUrl: _metadata?.thumbnailUrl,
      aspectRatio: _aspectRatio,
      icon: const AssetImage('assets/icons/vimeo-play.png'),
      onPlay: () => setState(() => _webViewShow = true),
    );
  }
}
