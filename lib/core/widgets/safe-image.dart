import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'onerror-reload.dart';

final placeholder = MemoryImage(kTransparentImage);

class AppSafeImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final BoxFit fit;
  final void Function(ImageInfo) onInfo;
  final bool showAnimation;
  final Color background;

  AppSafeImage(
      {Key key,
      this.imageProvider,
      this.fit = BoxFit.contain,
      this.onInfo,
      this.showAnimation = true,
      this.background})
      : super(key: key);

  @override
  _AppSafeImageState createState() => _AppSafeImageState();
}

class _AppSafeImageState extends State<AppSafeImage>
    with TickerProviderStateMixin {
  final _fadeInDuration = Duration(milliseconds: 200);
  bool _error = false;
  bool _animate = false;
  bool _loaded = false;
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    if (widget.showAnimation) {
      _controller = AnimationController(
          duration: const Duration(milliseconds: 500), vsync: this)
        ..repeat(reverse: true, min: 0.5, max: 1);
      _animation =
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
      _animate = true;
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
    widget.imageProvider
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, bool _) async {
          if (widget.onInfo != null && !_loaded) {
            _loaded = true;
            widget.onInfo(imageInfo);
          }
          await Future.delayed(_fadeInDuration);
          _animate = false;
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

    return ColoredBox(
      color: widget.background ?? (isDark ? Colors.black26 : Colors.grey[200]),
      child: Stack(children: <Widget>[
        if (_animate)
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Icon(Icons.image, color: Colors.grey[500], size: 44),
            ),
          ),
        FadeInImage(
          fit: widget.fit,
          fadeInDuration: _fadeInDuration,
          placeholder: placeholder,
          image: widget.imageProvider,
        ),
      ], fit: StackFit.expand),
    );
  }
}
