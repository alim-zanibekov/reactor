import 'dart:async';

import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/fade-icon.dart';
import '../../../core/widgets/onerror-reload.dart';
import '../../../variables.dart';

class AppVideoPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;

  AppVideoPlayer({Key key, @required this.url, this.aspectRatio = 16.0 / 9.0})
      : super(key: key);

  @override
  _AppVideoPlayerState createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  static List<VideoPlayerController> _cache = [];
  StreamController<int> _streamController;
  VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _initialized = false;
  bool _controllerDestroyed = false;

  @override
  void initState() {
    _streamController = StreamController();
    _load();
    super.initState();
  }

  @override
  void dispose() {
    try {
      final element = _cache.firstWhere((element) => element == _controller);
      _cache.remove(element);
    } on StateError {}
    if (_controller != null) {
      _controller.removeListener(_onChangeVideoState);
      _controller.dispose();
    }
    _streamController.close();
    super.dispose();
  }

  void _load() {
    if (_controllerDestroyed) {
      _controllerDestroyed = false;
      if (_cache.length >= 9) {
        final last = _cache.last;
        _cache.remove(last);
        last.setLooping(false);
      }
    } else if (_cache.length >= 9) {
      final first = _cache.first;
      _cache.removeAt(0);
      first.setLooping(false);
    }
    _controller = VideoPlayerController.network(widget.url,
        httpHeaders: REACTOR_VIDEO_HEADERS,
        maxCacheSize: 200 << 20,
        maxFileSize: 10 << 20)
      ..initialize()
      ..setLooping(true).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    _cache.add(_controller);

    _controller.addListener(_onChangeVideoState);
    _initialized = _controller.value.initialized;
    setState(() {});
  }

  void _onChangeVideoState() {
    if (_controllerDestroyed) {
      return;
    }
    if (!_cache.contains(_controller)) {
      _controllerDestroyed = true;
      _initialized = false;
      if (_streamController.hasListener) {
        _streamController.add(1);
        Future.delayed(Duration(milliseconds: 200)).then((value) {
          _controller.removeListener(_onChangeVideoState);
          _controller.dispose();
          _controller = null;
          _streamController.add(1);
        });
      }
      return;
    }

    if (_isPlaying != _controller.value.isPlaying) {
      _isPlaying = _controller.value.isPlaying;
      if (_streamController.hasListener) {
        _streamController.add(1);
      }
    }
    if (_initialized != _controller.value.initialized) {
      _initialized = _controller.value.initialized;
      if (_streamController.hasListener) {
        _streamController.add(1);
      }
    }
    if (_controller.value.hasError) {
      _controller.dispose();
      if (_streamController.hasListener) {
        _streamController.add(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _streamController.stream,
      builder: (_, __) {
        if (_controllerDestroyed || _controller == null) {
          return AspectRatio(
            aspectRatio: widget.aspectRatio < 2 ? widget.aspectRatio : 2,
            child: AppOnErrorReload(
              icon: const Icon(Icons.error_outline, size: 44),
              text: 'Данный объект был выгружен из памяти',
              onReloadPressed: () {
                _load();
              },
            ),
          );
        }
        if (_controller.value.hasError) {
          return AspectRatio(
            aspectRatio: widget.aspectRatio < 2 ? widget.aspectRatio : 2,
            child: AppOnErrorReload(
              text: 'Произошла ошибка при загруке',
              onReloadPressed: () {
                _load();
              },
            ),
          );
        }
        return AspectRatio(
          aspectRatio: widget.aspectRatio < 2 ? widget.aspectRatio : 2,
          key: ValueKey(widget.url),
          child: _initialized
              ? Stack(children: <Widget>[
                  ClipRect(child: VideoPlayer(_controller)),
                  GestureDetector(
                    onTap: () {
                      if (!_isPlaying) {
                        _controller.play();
                      } else {
                        _controller.pause();
                      }
                    },
                    child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isPlaying ? 0 : 1,
                        child: const DecoratedBox(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.5)),
                            child: Center(
                              child: Icon(Icons.play_arrow,
                                  size: 42, color: Colors.white),
                            ))),
                  ),
                  if (_isPlaying)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          _controller.seekTo(Duration.zero);
                          _controller.play();
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(
                              top: 10, right: 10, bottom: 20, left: 20),
                          child: IconShadowWidget(
                            const Icon(Icons.refresh,
                                size: 22, color: Colors.white),
                            shadowColor: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ])
              : FadeIcon(
                  key: ObjectKey(widget.url),
                  icon: Icon(Icons.gif, color: Colors.grey[500], size: 44),
                ),
        );
      },
    );
  }
}
