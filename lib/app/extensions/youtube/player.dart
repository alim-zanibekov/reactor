import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/common/metadata.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../common/options.dart';
import '../common/video-thumbnail.dart';

class AppYouTubePlayer extends StatefulWidget {
  final String videoId;
  final OEmbedMetadata metadata;
  final Future<OEmbedMetadata> futureMetadata;

  AppYouTubePlayer(
      {Key key, @required this.videoId, this.metadata, this.futureMetadata})
      : super(key: key);

  @override
  _AppYouTubePlayerState createState() => _AppYouTubePlayerState();
}

class _AppYouTubePlayerState extends State<AppYouTubePlayer>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController _webView;
  OEmbedMetadata _metadata;
  String _url;
  double _aspectRatio = 16.0 / 9.0;
  bool _webViewShow = false;
  bool _error = false;
  bool _wantKeepAlive = false;

  @override
  void initState() {
    _metadata = widget.metadata;
    if (_metadata != null) {
      _aspectRatio = _metadata.width / _metadata.height;
    } else {
      widget.futureMetadata.then((value) {
        _metadata = value;
        _aspectRatio = _metadata.width / _metadata.height;
        if (mounted) {
          setState(() {});
        }
      });
    }
    _url =
        'https://www.youtube.com/embed/${widget.videoId}?autoplay=0&html5=True&rel=0&showinfo=0&playsinline=1&controls=0';
    super.initState();
  }

  @override
  bool get wantKeepAlive => _wantKeepAlive;

  Widget getVideo() {
    return InAppWebView(
      key: ValueKey(_url),
      initialUrl: _url,
      initialOptions: inAppWebViewDefaultOptions(),
      onWebViewCreated: (InAppWebViewController controller) {
        _webView = controller;
      },
      onProgressChanged: (controller, _) {
        controller.injectCSSCode(source: _initPlayerCSS);
      },
      onLoadStop: (InAppWebViewController controller, String url) {
        controller.evaluateJavascript(source: _initPlayerJS);
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
            source: 'document.querySelector("video").pause()');

        canLaunch(request.url)
            .then((value) => value ? launch(request.url) : null);

        return ShouldOverrideUrlLoadingAction.CANCEL;
      },
      onLoadError: (InAppWebViewController controller, String url, err1, err2) {
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
        child: getVideo(),
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

String _initPlayerCSS = '''
  .ytp-bezel-text-hide, .ytp-watermark, .ytp-large-play-button { 
    display: none!important; 
  }
  video::-webkit-media-controls-overlay-play-button, video::-webkit-media-controls-panel, video::-webkit-media-controls {
      display: flex!important;
  }
  .html5-video-player, video {
    left: 0!important;
    top: 0!important;
    minHeight:  100vh!important;
    maxHeight: 100vh!important;
    minWidth: 100vh!important;
    maxWidth: 100vw!important;
  }
''';

String _initPlayerJS = '''(function() {
  document.elementFromPoint(window.innerWidth / 2, window.innerHeight / 2).click();
  
  const video = document.querySelector('video');
  const player = document.querySelector('.html5-video-player');
  const buttons = document.querySelector('.ytp-chrome-top-buttons');
  const replayBtn = document.querySelector('.ytp-replay-button');
 
  buttons.parentNode.removeChild(buttons);
  
  document.body.style.display = 'flex';
  document.body.style.alignItems = 'center';
  document.body.style.justifyContent = 'center';
  
  video.oncanplay = function () {
    replayBtn.style.top = '48vh';
    replayBtn.style.height = '36px';
  }
  
  const callback = function(mutationsList, observer) {
    observer.disconnect();
    player.classList.remove('ytp-big-mode');
    try {
      player.removeChild(document.querySelector('.videowall-endscreen'));
      player.removeChild(document.querySelector('.ytp-upnext'));
      player.removeChild(document.querySelector('.ytp-pause-overlay'));
    } catch(e) {}
    observer.observe(player, { attributes: true });
  }
  document.querySelector('.ytp-chrome-top').innerHTML = document.querySelector('.ytp-chrome-top').innerHTML;
  
  const observer = new MutationObserver(callback);
  observer.observe(player, { attributes: true });
})()
''';
