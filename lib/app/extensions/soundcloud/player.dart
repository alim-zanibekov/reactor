import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/external/error-reporter.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppSoundCloudPlayer extends StatefulWidget {
  final String url;
  final OEmbedMetadata? metadata;
  final Future<OEmbedMetadata>? futureMetadata;

  AppSoundCloudPlayer(
      {Key? key, required this.url, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppSoundCloudPlayerState createState() => _AppSoundCloudPlayerState();
}

class _AppSoundCloudPlayerState extends State<AppSoundCloudPlayer> {
  late String _url;
  OEmbedMetadata? _metadata;
  bool _webViewShow = false;

  bool _error = false;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
    if (_metadata == null) {
      widget.futureMetadata?.then((value) {
        _metadata = value;
        if (mounted) {
          setState(() {});
        }
      }).catchError((dynamic error, StackTrace stackTrace) {
        ErrorReporter.reportError(error, stackTrace);
      });
    }
    _url = 'https://w.soundcloud.com/player/'
        '?url=${Uri.encodeQueryComponent(widget.url)}';
  }

  Widget getVideo(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return InAppWebView(
          initialUrlRequest: URLRequest(url: Uri.parse(_url)),
          initialOptions: inAppWebViewDefaultOptions(),
          onProgressChanged: (controller, _) {
            controller.injectCSSCode(
              source: '.mobilePrestitial, .soundHeader__actions,'
                  ' .cookiePolicy { display: none!important;}',
            );
          },
          onLoadStop: (controller, _) {
            controller.evaluateJavascript(
              source: 'setTimeout(() => document.querySelector('
                  '".mobilePrestitial__link").click(), 1000)',
            );
          },
          shouldOverrideUrlLoading: (controller, request) async {
            final url = Uri.parse(request.request.url.toString());
            canLaunchUrl(url)
                .then((value) => value ? launchUrl(url) : Future.value(false));

            return NavigationActionPolicy.CANCEL;
          },
          onLoadError: (controller, _, err1, err2) {
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
      return SizedBox(
        height: 162.0,
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
      return SizedBox(
        height: 162.0,
        child: getVideo(context),
      );
    }

    return Container(
      height: 162,
      alignment: Alignment.center,
      child: VideoThumbnail(
        imageUrl: _metadata?.thumbnailUrl,
        aspectRatio: 1,
        icon: const AssetImage('assets/icons/soundcloud-play.png'),
        onPlay: () => setState(() => _webViewShow = true),
      ),
    );
  }
}
