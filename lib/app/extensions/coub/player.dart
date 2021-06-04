import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/external/error-reporter.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppCoubPlayer extends StatefulWidget {
  final String videoId;
  final OEmbedMetadata metadata;
  final Future<OEmbedMetadata> futureMetadata;

  AppCoubPlayer(
      {Key key, @required this.videoId, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppCoubPlayerState createState() => _AppCoubPlayerState();
}

class _AppCoubPlayerState extends State<AppCoubPlayer> {
  String _url;
  OEmbedMetadata metadata;
  double aspectRatio = 16.0 / 9.0;
  bool webViewShow = false;

  bool error = false;

  @override
  void initState() {
    super.initState();
    metadata = widget.metadata;

    if (metadata != null) {
      aspectRatio = metadata.width / metadata.height;
    } else {
      widget.futureMetadata.then((value) {
        metadata = value;
        aspectRatio = metadata.width / metadata.height;
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
              source: '.viewer__pause__share { display: none!important; }'
                  ' .viewer__click { opacity: 0!important; }',
            );
          },
          onLoadStop: (InAppWebViewController controller, Uri url) {
            controller.evaluateJavascript(
              source: 'document.querySelector(".viewer__click").click()',
            );
          },
          shouldOverrideUrlLoading: (controller, request) async {
            canLaunch(request.request.url.toString()).then((value) =>
                value ? launch(request.request.url.toString()) : null);

            return NavigationActionPolicy.CANCEL;
          },
          onLoadError:
              (InAppWebViewController controller, Uri url, err1, err2) {
            error = true;
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
    if (error) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: AppOnErrorReload(
          text: 'Произошла ошибка при загруке',
          onReloadPressed: () {
            setState(() {
              webViewShow = false;
              error = false;
            });
          },
        ),
      );
    }
    if (webViewShow) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: getVideo(context),
      );
    }

    return VideoThumbnail(
      imageUrl: metadata?.thumbnailUrl,
      aspectRatio: aspectRatio,
      icon: const AssetImage('assets/icons/coub-play.png'),
      onPlay: () => setState(() => webViewShow = true),
    );
  }
}
