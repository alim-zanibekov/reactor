import 'package:flutter/material.dart';
import 'package:reactor/core/common/retry-network-image.dart';
import 'package:reactor/core/widgets/fade-icon.dart';
import 'package:transparent_image/transparent_image.dart';

import 'onerror-reload.dart';

final placeholder = MemoryImage(kTransparentImage);

class AppSafeImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final BoxFit fit;
  final void Function(ImageInfo) onInfo;
  final bool showAnimation;
  final Color background;

  const AppSafeImage({
    Key key,
    this.imageProvider,
    this.fit = BoxFit.contain,
    this.onInfo,
    this.showAnimation = true,
    this.background,
  }) : super(key: key);

  @override
  _AppSafeImageState createState() => _AppSafeImageState();
}

class _AppSafeImageState extends State<AppSafeImage> {
  final _fadeInDuration = Duration(milliseconds: 200);
  bool _error = false;
  bool _loaded = false;
  bool _animate = false;
  bool _withoutFades = false;
  bool _mayBeTransparent = false;
  AnimationController _controller;

  @override
  void initState() {
    _animate = widget.showAnimation;
    if (widget.imageProvider is AppNetworkImageWithRetry) {
      final url = (widget.imageProvider as AppNetworkImageWithRetry).url;
      _mayBeTransparent = url.endsWith('png') || url.endsWith('gif');
    }
    _load();
    super.initState();
  }

  @override
  void dispose() {
    if (_error) {
      widget.imageProvider.evict();
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppSafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() async {
    if (_loaded) {
      return;
    }
    if (_error) {
      setState(() {
        _error = false;
      });
      await widget.imageProvider.evict();
    }

    if (widget.imageProvider is AppNetworkImageWithRetry && _animate) {
      _withoutFades = _animate =
          !(await (widget.imageProvider as AppNetworkImageWithRetry)
              .existInCache());
    }

    widget.imageProvider
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, bool _) async {
          if (widget.onInfo != null && !_loaded) {
            _loaded = true;
            widget.onInfo(imageInfo);
          }
          if (_animate) {
            await Future.delayed(_fadeInDuration);
            _animate = false;
          }
          if (mounted) {
            setState(() {});
          }
        }, onError: (obj, stack) {
          _error = true;
          _animate = false;
          if (mounted) {
            setState(() {});
          }
        }));

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return AppOnErrorReload(
        text: 'При загрузке изображения произошла ошибка',
        onReloadPressed: () async {
          await widget.imageProvider.evict();
          _load();
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        widget.background ?? (isDark ? Colors.black26 : Colors.grey[200]);

    return ColoredBox(
      color: color,
      child: Stack(children: <Widget>[
        if (_animate)
          FadeIcon(
            color: color,
            icon: Icon(Icons.image, color: Colors.grey[500], size: 44),
          ),
        if (_mayBeTransparent && _withoutFades)
          ColoredBox(
            color: _loaded ? Colors.white : Colors.transparent,
            child: Image(
              fit: widget.fit,
              image: widget.imageProvider,
            ),
          )
        else
          AnimatedOpacity(
            opacity: _animate ? 0 : 1,
            duration: _fadeInDuration,
            curve: Curves.easeIn,
            child: ColoredBox(
              color: Colors.white,
              child: Image(
                fit: widget.fit,
                image: widget.imageProvider,
              ),
            ),
          )
      ], fit: StackFit.expand),
    );
  }
}
