import 'dart:async';

import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:video_player/video_player.dart';

import '../../../core/preferences/preferences.dart';
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
  final preferences = Preferences();
  static List<VideoPlayerController> _cache = [];
  VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _controllerDestroyed = false;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    _load();
    super.initState();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _notify() {
    if (mounted) {
      setState(() {});
    }
  }

  void _disposeController() {
    try {
      final element = _cache.firstWhere((element) => element == _controller);
      _cache.remove(element);
    } on StateError {}

    if (_controller != null) {
      _controller.removeListener(_onChangeVideoState);
      _controller.dispose();
      _controller = null;
    }
  }

  void _removeFromCacheAndNotify(VideoPlayerController ctrl) {
    if (_cache.length >= 9) {
      _cache.remove(ctrl);
      ctrl.setLooping(false);
    }
  }

  Future _safeRemoveController() async {
    await Future.delayed(const Duration(milliseconds: 30));
    _notify();
    await Future.delayed(const Duration(milliseconds: 100));
    _disposeController();
    _notify();
  }

  void _load() {
    _initialized = false;
    _hasError = false;

    if (_controllerDestroyed) {
      _controllerDestroyed = false;
      _removeFromCacheAndNotify(_cache.isNotEmpty ? _cache.last : null);
    } else {
      _removeFromCacheAndNotify(_cache.isNotEmpty ? _cache.first : null);
    }

    if (mounted) {
      _controller = VideoPlayerController.network(
        widget.url,
        httpHeaders: Headers.videoHeaders,
        maxCacheSize: 200 << 20,
        maxFileSize: 10 << 20,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      )
        ..setLooping(true)
        ..initialize();

      _cache.add(_controller);
      _controller.addListener(_onChangeVideoState);
      _initialized = _controller.value.initialized;

      _notify();
    }
  }

  void _onChangeVideoState() async {
    if (_controllerDestroyed) {
      return;
    }
    if (!_cache.contains(_controller)) {
      _controllerDestroyed = true;
      _initialized = false;
      await _safeRemoveController();
      return;
    }

    if (_isPlaying != _controller.value.isPlaying) {
      _isPlaying = _controller.value.isPlaying;
      _notify();
    }

    if (_initialized != _controller.value.initialized) {
      _initialized = _controller.value.initialized;
      if (preferences.gifAutoPlay) {
        _controller.play();
      }
      _notify();
    }

    if (_controller.value.hasError) {
      _hasError = _controller.value.hasError;
      await _safeRemoveController();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controllerDestroyed) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio < 2 ? widget.aspectRatio : 2,
        child: AppOnErrorReload(
          icon: const Icon(Icons.error_outline, size: 44),
          text: 'Данный объект был выгружен из памяти',
          onReloadPressed: () => _load(),
        ),
      );
    }
    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio < 2 ? widget.aspectRatio : 2,
        child: AppOnErrorReload(
          text: 'Произошла ошибка при загруке',
          onReloadPressed: () => _load(),
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
                color: Color.fromRGBO(0, 0, 0, 0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),
          ),
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
                  top: 10,
                  right: 10,
                  bottom: 20,
                  left: 20,
                ),
                child: IconShadowWidget(
                  const Icon(
                    Icons.refresh,
                    size: 22,
                    color: Colors.white,
                  ),
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
  }
}
