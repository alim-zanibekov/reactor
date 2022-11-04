import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/external/error-reporter.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppYouTubePlayer extends StatefulWidget {
  final String? videoId;
  final OEmbedMetadata? metadata;
  final Future<OEmbedMetadata>? futureMetadata;

  AppYouTubePlayer(
      {Key? key, required this.videoId, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppYouTubePlayerState createState() => _AppYouTubePlayerState();
}

class _AppYouTubePlayerState extends State<AppYouTubePlayer>
    with AutomaticKeepAliveClientMixin {
  late InAppWebViewController _webView;
  OEmbedMetadata? _metadata;
  String? _url;
  double _aspectRatio = 16.0 / 9.0;
  bool _webViewShow = false;
  bool _error = false;
  bool _wantKeepAlive = false;

  @override
  void initState() {
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
    _url = 'https://www.youtube.com/embed/${widget.videoId}?autoplay=0'
        '&html5=True&rel=0&showinfo=0&playsinline=1&controls=1';

    super.initState();
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  String _generatePage() {
    return '''<!DOCTYPE html>
      <html lang="en">
      <head>
          <meta name="viewport" content="width=device-width, initial-scale=1"/>
      </head>
      <body style="margin: 0">
          <iframe type="text/html" style="width: 100vw; height: calc(100vw / $_aspectRatio)"
                  src="https://www.youtube.com/embed" frameborder="0" allowfullscreen/>
      </body>
      </html>
    ''';
  }

  Widget getVideo(BuildContext context) {
    return InAppWebView(
      key: ValueKey(_url),
      initialData: InAppWebViewInitialData(
        data: _generatePage(),
      ),
      initialOptions: inAppWebViewDefaultOptions(),
      onWebViewCreated: (InAppWebViewController controller) {
        _webView = controller;
      },
      onEnterFullscreen: (_) {
        _wantKeepAlive = true;
        updateKeepAlive();
      },
      onExitFullscreen: (_) {
        _wantKeepAlive = false;
        updateKeepAlive();
      },
      shouldOverrideUrlLoading: (controller, request) async {
        _webView.evaluateJavascript(
            source:
                "document.querySelector('iframe').contentWindow.postMessage({ type: 'pause'}, '*');");

        final url = Uri.parse(request.request.url.toString());
        canLaunchUrl(url).then((value) => value
            ? launchUrl(url, mode: LaunchMode.externalApplication)
            : Future.value(false));

        return NavigationActionPolicy.CANCEL;
      },
      androidShouldInterceptRequest: (controller, request) async {
        if (request.url.toString() == 'https://www.youtube.com/embed') {
          return WebResourceResponse(
            contentEncoding: 'utf-8',
            contentType: "text/html",
            data: Uint8List.fromList('''<!DOCTYPE html>
            <html lang="en">
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
            </head>
            <body style="margin: 0">
                <iframe type="text/html" style="width: 100vw; height: 100vh"
                        src="$_url" frameborder="0" allowfullscreen onload="fixYouTubePlayer()"></iframe>
                <script>$_initPlayerJS</script>
            </body>
            </html>
            '''
                .codeUnits),
            statusCode: 200,
            reasonPhrase: 'OK',
          );
        }
        return null;
      },
      onLoadError: (controller, url, err1, err2) {
        _error = true;
        if (mounted) {
          setState(() {});
        }
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
      icon: const AssetImage('assets/icons/youtube-play.png'),
      onPlay: () => setState(() => _webViewShow = true),
    );
  }
}

String _initPlayerJS = '''function fixYouTubePlayer() {
  const doc = document.querySelector('iframe').contentWindow.document;
  const style = doc.createElement('style');
  style.type = 'text/css';
  style.appendChild(document.createTextNode(`
    .ytp-bezel-text-hide, .ytp-watermark, .ytp-large-play-button { 
      display: none!important; 
    }
  `));
  doc.head.appendChild(style);

  doc.elementFromPoint(window.innerWidth / 2, window.innerHeight / 2).click();
  
  const video = doc.querySelector('video');
  const player = doc.querySelector('.html5-video-player');
  const buttons = doc.querySelector('.ytp-chrome-top-buttons');
  const replayBtn = doc.querySelector('.ytp-replay-button');
  
  buttons.parentNode.removeChild(buttons);
  
  const replay = doc.createElement('button');
  replay.style = 'display: none; top: 50vh; height: 36px; margin-top: -18px;' +
    'z-index: 10000; position: absolute; background: transparent; border: 0;' + 
    'left: 50vw; margin-left: -18px;';
  replay.innerHTML = '<div class="ytp-icon ytp-icon-replay"></div>';
  
  setTimeout(function () {
    player.appendChild(replay);
  }, 2000);
  
  video.onended = function () {
    replay.style.display = 'block';
  };
  
  replay.onclick = function () {
    replay.style.display = 'none';
    video.pause();
    video.currentTime = 0;
    video.play();
  };
  
  player.appendChild(replay);
  
  doc.body.style.display = 'flex';
  doc.body.style.alignItems = 'center';
  doc.body.style.justifyContent = 'center';
  
  const callback = function(mutationsList, observer) {
    observer.disconnect();
    player.classList.remove('ytp-big-mode');
    try {
      player.removeChild(doc.querySelector('.videowall-endscreen'));
      player.removeChild(doc.querySelector('.ytp-upnext'));
      player.removeChild(doc.querySelector('.ytp-pause-overlay'));
    } catch(e) {}
    observer.observe(player, { attributes: true });
  }
  doc.querySelector('.ytp-chrome-top').innerHTML = 
    doc.querySelector('.ytp-chrome-top').innerHTML;
  
  const observer = new MutationObserver(callback);
  observer.observe(player, { attributes: true });
  
  window.addEventListener('message', function (e) {
    video.pause();
  });
}
''';
