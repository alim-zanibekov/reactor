import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/external/error-reporter.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppCoubPlayer extends StatefulWidget {
  final String? videoId;
  final OEmbedMetadata? metadata;
  final Future<OEmbedMetadata>? futureMetadata;

  AppCoubPlayer(
      {Key? key, required this.videoId, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppCoubPlayerState createState() => _AppCoubPlayerState();
}

class _AppCoubPlayerState extends State<AppCoubPlayer> {
  late String _url;
  OEmbedMetadata? _metadata;
  double _aspectRatio = 16.0 / 9.0;
  bool _webViewShow = false;

  bool _error = false;

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
    _url = 'https://coub.com/embed/${widget.videoId}';
  }

  Widget getVideo(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(_url)),
          initialOptions: inAppWebViewDefaultOptions(),
          onProgressChanged: (controller, _) {
            controller.injectCSSCode(
              source: '.viewer__share__social.copy, .viewer__get-app,'
                  ' .viewer__open-in-app, .viewer-music-inner.-double'
                  ' { display: none!important; }'
                  ' .viewer__click { opacity: 0!important; }'
                  ' .viewer__floating-controls { text-align: right; padding: 5px 0 0; }',
            );
          },
          onLoadStop: (InAppWebViewController controller, Uri? url) {
            controller.evaluateJavascript(
              source: 'document.querySelector(".viewer__click").click()',
            );
          },
          shouldOverrideUrlLoading: (controller, request) async {
            final url = Uri.parse(request.request.url.toString());
            canLaunchUrl(url)
                .then((value) => value ? launchUrl(url, mode: LaunchMode.externalApplication)
                : Future.value(false));

            return NavigationActionPolicy.CANCEL;
          },
          onLoadError:
              (InAppWebViewController controller, Uri? url, err1, err2) {
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
      icon: const AssetImage('assets/icons/coub-play.png'),
      onPlay: () => setState(() => _webViewShow = true),
    );
  }
}
