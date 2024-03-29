import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../../core/common/menu.dart';
import '../../core/common/retry-network-image.dart';
import '../../core/common/save-file.dart';
import '../../core/common/snack-bar.dart';
import '../../core/common/value-updater.dart';
import '../../core/widgets/gesture-detector.dart';
import '../../core/widgets/safe-image.dart';

class _AnimationControllerInner extends AnimationController {
  _AnimationControllerInner({
    Duration? duration,
    required TickerProvider vsync,
  }) : super(vsync: vsync, duration: duration);

  void notifyAll() => this.notifyListeners();
}

class ImageGalleryScreen extends StatelessWidget {
  final List<ImageProvider>? imageProviders;
  final int? selectedIndex;

  ImageGalleryScreen({Key? key, this.imageProviders, this.selectedIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.black,
        child: ImageGallery(
          imageProviders: imageProviders!,
          selectedIndex: selectedIndex!,
          onClose: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class ImageGallery extends StatefulWidget {
  final List<ImageProvider> imageProviders;
  final void Function()? onClose;
  final int selectedIndex;

  ImageGallery(
      {required this.imageProviders, required this.selectedIndex, this.onClose})
      : assert(selectedIndex >= 0),
        assert(selectedIndex < imageProviders.length),
        super();

  @override
  State<StatefulWidget> createState() {
    return _ImageGalleryState();
  }
}

class _ImageGalleryState extends State<ImageGallery>
    with TickerProviderStateMixin {
  final _defaultDuration = Duration(milliseconds: 150);

  late double _maxWidth;
  late double _maxHeight;
  late List<ImageUnit> _images;
  late ScrollController _scrollController;
  late _AnimationControllerInner _controllerImage;
  late _AnimationControllerInner _controllerMove;
  late ImageUnit _activeImage;

  bool calledBuild = false;

  bool _animating = false;

  bool _dragVertical = false,
      _dragHorizontal = false,
      _canSlideLeft = false,
      _canSlideRight = false,
      _scaleChanged = false;

  Offset? _moveDirection;

  Matrix4? _movingMatrix;

  ValueUpdater<double> _scrollUpdater = ValueUpdater((a, b) => b - a, 0);

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);
    super.dispose();
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    _controllerImage = _AnimationControllerInner(
      duration: _defaultDuration,
      vsync: this,
    );
    _controllerMove = _AnimationControllerInner(
      duration: _defaultDuration,
      vsync: this,
    );
    _controllerImage.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animating = false;
      }
    });

    _controllerMove.addListener(() {
      final md = _moveDirection;
      if (md == null) return;

      final e = _controllerMove.value;
      final transform = _movingMatrix
        ?..translate(-md.dx * e * 4, -md.dy * e * 4);
      _activeImage.transform = transform ?? Matrix4.identity();
      _activeImage.boxer.clamp(_activeImage.transform);
      _controllerImage.notifyAll();
    });

    _scrollController = ScrollController();

    super.initState();
  }

  void _onStart(MatrixGestureDetectorDetails details) {
    if (_animating || _activeImage.info == null) return;

    _scaleChanged = _dragVertical = _dragHorizontal = false;
    _activeImage.transformPrev = _activeImage.transform.clone();
    _scrollUpdater.value = details.position.dx;

    final rect = _activeImage.boxer.getRect(_activeImage.transform);
    _canSlideLeft = rect.left.round() == 0 && _images.indexOf(_activeImage) > 0;
    _canSlideRight = rect.right.round() == _maxWidth.round() &&
        _images.indexOf(_activeImage) < _images.length - 1;

    _controllerMove.stop();
  }

  void _onUpdate(MatrixGestureDetectorOnUpdateDetails details) {
    if (_animating || _activeImage.info == null) return;
    final decomposedValues =
        MatrixGestureDetector.decomposeToValues(_activeImage.transform);
    if (details.scale == 1) {
      final canDragVertical = decomposedValues.right == 1;
      final velocity = details.velocityEstimate;
      if (velocity == null || velocity.offset == Offset.zero) {
        return;
      }
      final check = _scrollUpdater.check(details.position.dx);

      if (!_dragVertical &&
          (_canSlideLeft && check > 0 ||
              _canSlideRight && check < 0 ||
              _dragHorizontal) &&
          (_dragHorizontal ||
              velocity.offset.dx.abs() > velocity.offset.dy.abs())) {
        _dragHorizontal = true;
        final scrollDelta = _scrollUpdater.update(details.position.dx);
        _scrollController.jumpTo(_scrollController.offset - scrollDelta);
        return;
      } else if (canDragVertical && !_dragHorizontal) {
        _dragVertical = true;
        _activeImage.transform =
            details.translateMatrix * _activeImage.transform;
        _activeImage.boxer
            .restrictHorizontalMoveAndScale(_activeImage.transform);
        _controllerImage.notifyAll();
        return;
      }
    } else {
      _scaleChanged = true;
    }

    if (!_dragHorizontal) {
      _canSlideLeft = false;
      _canSlideRight = false;
      _activeImage.transform = details.scaleMatrix *
          details.translateMatrix *
          _activeImage.transform;
      _activeImage.boxer.clamp(_activeImage.transform, restrictLowScale: false);
    }
    _controllerImage.notifyAll();
  }

  void _onEnd(MatrixGestureDetectorDetails details) async {
    final velocity = details.velocityEstimate;
    if (_animating || _activeImage.info == null || velocity == null) return;

    if (_dragVertical) {
      if (velocity.pixelsPerSecond.distance >= 100.0 &&
          velocity.offset.dy.abs() > 40) {
        widget.onClose?.call();
      } else {
        _animating = true;
        _activeImage.transformPrev = _activeImage.transform.clone();
        _activeImage.transform = _activeImage.initialMatrix.clone();
        _controllerImage.forward(from: 0);
      }
    } else if (_dragHorizontal) {
      final imageIndex = _images.indexOf(_activeImage);
      var scroll = imageIndex * _maxWidth;
      final scrollDiff = _scrollController.offset - scroll;
      final speed = velocity.pixelsPerSecond.dx;
      if (speed.abs() > 50 || scrollDiff.abs() > _maxWidth * 0.6) {
        if (speed > 0 && scrollDiff > 0 && imageIndex < _images.length - 1) {
          _activeImage = _images[imageIndex + 1];
          scroll += _maxWidth;
        } else if (speed < 0 && scrollDiff < 0 && imageIndex > 0) {
          _activeImage = _images[imageIndex - 1];
          scroll -= _maxWidth;
        }
      }

      _scrollController.animateTo(scroll,
          duration: _defaultDuration, curve: Curves.easeInOut);
      _animating = true;
      await Future.delayed(_defaultDuration);
      _animating = false;
    } else {
      final magnitude = velocity.pixelsPerSecond.distance;

      if (_scaleChanged) {
        _animating = true;
        _activeImage.transformPrev = _activeImage.transform.clone();
        _activeImage.boxer.clamp(_activeImage.transform);
        _controllerImage.forward(from: 0);
      } else if (magnitude >= 400.0) {
        _moveDirection = velocity.pixelsPerSecond / magnitude;
        _activeImage.transformPrev = _activeImage.transform.clone();
        _movingMatrix = _activeImage.transform.clone();
        _controllerMove.value = 1;
        _controllerMove.animateTo(0,
            curve: Curves.easeInOut, duration: Duration(milliseconds: 500));
      }
    }
  }

  void _onDoubleTap(MatrixGestureDetectorDetails details) {
    if (_animating || _activeImage.info == null) return;
    _animating = true;

    final decomposedValues =
        MatrixGestureDetector.decomposeToValues(_activeImage.transform);
    if (decomposedValues.right > 1) {
      _activeImage.transformPrev = _activeImage.transform.clone();
      _activeImage.transform = _activeImage.initialMatrix.clone();
      _controllerImage.forward(from: 0);
    } else {
      _activeImage.transformPrev = _activeImage.transform.clone();
      final screenAspectRatio = _maxWidth / _maxHeight;
      _activeImage.boxer.fit(
        _activeImage.transform,
        details.position,
        scaleDelta: screenAspectRatio > _activeImage.aspectRatio ? 0 : 0.1,
      );
      _activeImage.boxer.clamp(_activeImage.transform);
      _controllerImage.forward(from: 0);
    }
  }

  void _onInfo(ImageInfo info, ImageUnit image) async {
    final aspectRatio = info.image.width / info.image.height;
    final screenAspectRatio = _maxWidth / _maxHeight;

    double? width = _maxWidth, height = _maxWidth / aspectRatio;
    if (screenAspectRatio > aspectRatio) {
      height = _maxHeight;
      width = _maxHeight * aspectRatio;
    }

    image.size = Size(width, height);

    image.transform = Matrix4.identity();
    image.transform
        .leftTranslate((_maxWidth - width) / 2, (_maxHeight - height) / 2);
    image.transformPrev = image.transform.clone();
    image.initialMatrix = image.transform.clone();
    image.boxer = Boxer(Rect.fromLTWH(0, 0, _maxWidth, _maxHeight),
        Rect.fromLTWH(0, 0, width, height));
    image.info = info;
    if (screenAspectRatio > aspectRatio) {
      image.boxer.fit(image.transform, Offset(_maxWidth / 2, 0));
      image.boxer.clamp(image.transform);
    }

    image.ready = true;
    await Future.delayed(Duration(milliseconds: 0));
    _controllerImage.notifyAll();
  }

  Widget copyLinkPopup() {
    final menu = Menu(context, items: [
      SimpleMenuItem(
          text: 'Сохранить в загрузки',
          onSelect: () async {
            if (_activeImage.info == null) {
              SnackBarHelper.show(context, 'Дождитесь загрузки изображения');
              return;
            }
            final image =
                _activeImage.imageProvider as AppNetworkImageWithRetry;
            final rawBytes = await image.loadContentsFromDiskCache();
            final url = image.url;
            if (rawBytes != null) {
              await SaveFile.save(context, url, rawBytes);
            } else {
              SnackBarHelper.show(context, 'Не удалось загрузить изображение');
            }
          }),
      SimpleMenuItem(
        text: "Поделиться",
        onSelect: () async {
          if (_activeImage.info == null) {
            SnackBarHelper.show(context, 'Дождитесь загрузки изображения');
            return;
          }
          final image = _activeImage.imageProvider as AppNetworkImageWithRetry;
          final file = await image.loadFromDiskCache();
          if (file != null) {
            Share.shareXFiles([XFile(file.path)]);
          }
        },
      )
    ]);

    return PopupMenuButton<int>(
      offset: const Offset(0, 50),
      padding: EdgeInsets.zero,
      tooltip: 'Меню',
      icon: Icon(Icons.more_vert, color: Colors.grey[300]),
      itemBuilder: (context) => menu.rawItems,
      onSelected: (index) => menu.process(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    _maxWidth = media.size.width;
    _maxHeight = media.size.height;

    if (!calledBuild) {
      calledBuild = true;
      _images = widget.imageProviders
          .map((e) => ImageUnit(
                size: Size(_maxWidth, _maxHeight),
                imageProvider: e,
              ))
          .toList();

      _activeImage = _images[widget.selectedIndex];
    }
    return Stack(children: <Widget>[
      MatrixGestureDetector(
        onDoubleTap: _onDoubleTap,
        onUpdate: _onUpdate,
        onStart: _onStart,
        onEnd: _onEnd,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          physics: NeverScrollableScrollPhysics(),
          child: OrientationBuilder(builder: (context, orientation) {
            final media = MediaQuery.of(context);
            _maxWidth = media.size.width;
            _maxHeight = media.size.height;

            _images.forEach((image) {
              final info = image.info;
              if (info != null) {
                _onInfo(info, image);
              }
            });

            Future.microtask(() {
              _scrollController.jumpTo(widget.selectedIndex * _maxWidth);
            });

            return Row(
              children: _images
                  .map(
                    (image) => Container(
                      height: _maxHeight,
                      width: _maxWidth,
                      alignment: Alignment.topLeft,
                      child: AnimatedBuilder(
                        animation: _controllerImage,
                        builder: (BuildContext context, Widget? child) {
                          child = SizedBox(
                            width: image.size.width,
                            height: image.size.height,
                            child: AppSafeImage(
                              background: Colors.black,
                              imageProvider: image.imageProvider,
                              fit: BoxFit.contain,
                              onInfo: (info) => _onInfo(info, image),
                            ),
                          );

                          if (!image.ready) {
                            return child;
                          }

                          return Transform(
                            transform: _animating
                                ? MatrixScaleTranslate4Tween(
                                    begin: image.transformPrev,
                                    end: image.transform,
                                  ).evaluate(_controllerImage)
                                : image.transform,
                            child: child,
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: copyLinkPopup(),
      ),
    ]);
  }
}

class ImageUnit {
  final ImageProvider imageProvider;
  Size size;

  ImageInfo? info;
  late Matrix4 initialMatrix;
  late Boxer boxer;
  late Matrix4 transformPrev;
  Matrix4 transform = Matrix4.identity();

  bool ready = false;

  double get aspectRatio => size.width / size.height;

  ImageUnit({required this.imageProvider, required this.size});
}

class MatrixScaleTranslate4Tween extends Tween<Matrix4> {
  MatrixScaleTranslate4Tween({
    required Matrix4 begin,
    required Matrix4 end,
  }) : super(begin: begin, end: end);
  static final vector.Quaternion rotationTrash = vector.Quaternion.identity();

  @override
  Matrix4 lerp(double t) {
    final vector.Vector3 beginTranslation = vector.Vector3.zero();
    final vector.Vector3 endTranslation = vector.Vector3.zero();
    final vector.Vector3 beginScale = vector.Vector3.zero();
    final vector.Vector3 endScale = vector.Vector3.zero();
    begin?.decompose(beginTranslation, rotationTrash, beginScale);
    end?.decompose(endTranslation, rotationTrash, endScale);

    final vector.Vector3 lerpTranslation =
        beginTranslation * (1.0 - t) + endTranslation * t;
    final vector.Vector3 lerpScale = beginScale * (1.0 - t) + endScale * t;

    return Matrix4.compose(
      lerpTranslation,
      vector.Quaternion.identity(),
      lerpScale,
    );
  }
}
