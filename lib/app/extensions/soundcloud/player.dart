import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppSoundCloudPlayer extends StatefulWidget {
  final String url;
  final OEmbedMetadata metadata;
  final Future<OEmbedMetadata> futureMetadata;

  AppSoundCloudPlayer(
      {Key key, @required this.url, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppSoundCloudPlayerState createState() => _AppSoundCloudPlayerState();
}

class _AppSoundCloudPlayerState extends State<AppSoundCloudPlayer> {
  String url;
  OEmbedMetadata metadata;
  bool webViewShow = false;

  bool error = false;

  @override
  void initState() {
    super.initState();
    metadata = widget.metadata;
    if (metadata == null) {
      widget.futureMetadata.then((value) {
        metadata = value;
        if (mounted) {
          setState(() {});
        }
      });
    }
    url =
        'https://w.soundcloud.com/player/?url=${Uri.encodeQueryComponent(widget.url)}';
  }

  Widget getVideo(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return InAppWebView(
          initialUrl: url,
          initialOptions: inAppWebViewDefaultOptions(),
          onProgressChanged: (controller, _) {
            controller.injectCSSCode(
                source:
                    '.mobilePrestitial, .soundHeader__actions, .cookiePolicy { display: none!important;}');
          },
          onLoadStop: (controller, _) {
            controller.evaluateJavascript(
                source:
                    'setTimeout(() => document.querySelector(".mobilePrestitial__link").click(), 1000)');
          },
          shouldOverrideUrlLoading: (controller, request) async {
            canLaunch(request.url)
                .then((value) => value ? launch(request.url) : null);
            return ShouldOverrideUrlLoadingAction.CANCEL;
          },
          onLoadError: (controller, _, err1, err2) {
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
      return SizedBox(
        height: 162.0,
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
      return SizedBox(
        height: 162.0,
        child: getVideo(context),
      );
    }

    return Container(
      height: 162,
      alignment: Alignment.center,
      child: VideoThumbnail(
        imageUrl: metadata?.thumbnailUrl,
        aspectRatio: 1,
        icon: const AssetImage('assets/icons/soundcloud-play.png'),
        onPlay: () => setState(() => webViewShow = true),
      ),
    );
  }
}
