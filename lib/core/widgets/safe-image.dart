import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../common/retry-network-image.dart';
import '../widgets/fade-icon.dart';
import 'onerror-reload.dart';

class AppSafeImage extends StatefulWidget {
  final ImageProvider? imageProvider;
  final BoxFit fit;
  final void Function(ImageInfo)? onInfo;
  final bool showAnimation;
  final Color? background;

  const AppSafeImage({
    Key? key,
    this.imageProvider,
    this.fit = BoxFit.cover,
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
  bool _animated = false;
  bool _hasAlphaChannel = false;
  AnimationController? _controller;
  ui.Image? image;

  @override
  void initState() {
    _animate = widget.showAnimation;

    if (widget.imageProvider is AppNetworkImageWithRetry) {
      final url =
          (widget.imageProvider as AppNetworkImageWithRetry).url.toLowerCase();
      if (url.endsWith('.gif') || url.endsWith('.apng')) {
        _animated = true;
        _hasAlphaChannel = true;
      } else if (url.endsWith('.png')) {
        _hasAlphaChannel = true;
      }
    }

    _load();

    super.initState();
  }

  @override
  void dispose() {
    if (_error) {
      widget.imageProvider!.evict();
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
      await widget.imageProvider!.evict();
    }

    if (widget.imageProvider is AppNetworkImageWithRetry && _animate) {
      _animate = !(await (widget.imageProvider as AppNetworkImageWithRetry)
          .existInCache());
      _withoutFades = !_animate;
    }

    widget.imageProvider!
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, bool _) async {
          image = imageInfo.image;
          if (widget.onInfo != null && !_loaded) {
            _loaded = true;
            widget.onInfo!(imageInfo);
          }
          if (_animate) {
            await Future.delayed(_fadeInDuration);
            _animate = false;
          }
          if (mounted) {
            setState(() {});
          }
        }, onError: (error, stack) {
          print(error);
          print(stack);
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

  Widget _buildImageWithSubstrate() {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Image(
        image: widget.imageProvider!,
        fit: widget.fit,
      ),
    );
  }

  Widget _buildImageOnCanvas() {
    return CustomPaint(
      painter: CustomImagePainter(
        image: image,
        backgroundColor: Colors.white,
        fit: widget.fit,
      ),
    );
  }

  Widget _buildImage() {
    if (_animated) {
      return _buildImageWithSubstrate();
    } else if (_hasAlphaChannel && _loaded) {
      return _buildImageOnCanvas();
    }
    return Image(
      image: widget.imageProvider!,
      fit: widget.fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return AppOnErrorReload(
        text: 'При загрузке изображения произошла ошибка',
        onReloadPressed: () async {
          await widget.imageProvider!.evict();
          _load();
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        widget.background ?? (isDark ? Colors.black26 : Colors.grey[200]!);

    return ColoredBox(
      color: color,
      child: Stack(children: <Widget>[
        if (_animate)
          FadeIcon(
            color: color,
            icon: Icon(Icons.image, color: Colors.grey[500], size: 44),
          ),
        if (_withoutFades)
          _buildImage()
        else
          AnimatedOpacity(
            opacity: _animate ? 0 : 1,
            duration: _fadeInDuration,
            curve: Curves.easeIn,
            child: _buildImage(),
          )
      ], fit: StackFit.expand),
    );
  }
}

class CustomImagePainter extends CustomPainter {
  final Color backgroundColor;
  final ui.Image? image;
  final BoxFit fit;

  CustomImagePainter(
      {required this.image,
      required this.backgroundColor,
      this.fit = BoxFit.cover});

  @override
  void paint(Canvas canvas, Size size) {
    final outputRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Size imageSize =
        Size(image!.width.toDouble(), image!.height.toDouble());
    final FittedSizes sizes = applyBoxFit(
      fit,
      imageSize,
      outputRect.size,
    );
    final Rect inputSubRect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubRect =
        Alignment.center.inscribe(sizes.destination, outputRect);
    canvas.drawImageRect(image!, inputSubRect, outputSubRect, new Paint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
