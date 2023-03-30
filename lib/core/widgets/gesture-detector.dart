import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../common/pair.dart';
import '../common/value-updater.dart';

class MatrixGestureDetectorDetails {
  final Offset position;
  final VelocityTracker? _velocityTracker;

  const MatrixGestureDetectorDetails(
      {required this.position, VelocityTracker? velocityTracker})
      : this._velocityTracker = velocityTracker;

  VelocityEstimate? get velocityEstimate =>
      _velocityTracker?.getVelocityEstimate();
}

class MatrixGestureDetectorOnUpdateDetails
    extends MatrixGestureDetectorDetails {
  final Matrix4 translateMatrix;
  final Matrix4 scaleMatrix;
  final double scale;
  final VelocityTracker? _velocityTracker;

  const MatrixGestureDetectorOnUpdateDetails({
    required Offset position,
    required this.scale,
    VelocityTracker? velocityTracker,
    required this.translateMatrix,
    required this.scaleMatrix,
  })  : this._velocityTracker = velocityTracker,
        super(position: position, velocityTracker: velocityTracker);
}

typedef GestureDetectorCallback<T> = void Function(T details);

class MatrixGestureDetector extends StatefulWidget {
  final Widget child;
  final GestureDetectorCallback<MatrixGestureDetectorDetails>? onStart;
  final GestureDetectorCallback<MatrixGestureDetectorOnUpdateDetails>? onUpdate;
  final GestureDetectorCallback<MatrixGestureDetectorDetails>? onEnd;
  final GestureDetectorCallback<MatrixGestureDetectorDetails>? onDoubleTap;

  const MatrixGestureDetector({
    Key? key,
    required this.child,
    this.onStart,
    this.onUpdate,
    this.onEnd,
    this.onDoubleTap,
  }) : super(key: key);

  static Matrix4 translateMatrix(Offset translation) {
    final dx = translation.dx;
    final dy = translation.dy;
    return Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1);
  }

  static Matrix4 scaleMatrix(double scale, Offset focalPoint) {
    final dx = (1 - scale) * focalPoint.dx;
    final dy = (1 - scale) * focalPoint.dy;
    return Matrix4(scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1);
  }

  static Pair<Offset, double> decomposeToValues(Matrix4 matrix) {
    final array = matrix.applyToVector3Array([0, 0, 0, 1, 0, 0]);
    Offset translation = Offset(array[0], array[1]);
    double scale = Offset(array[3] - array[0], array[4] - array[1]).distance;
    return Pair(translation, scale);
  }

  @override
  _MatrixGestureDetectorState createState() => _MatrixGestureDetectorState();
}

class _MatrixGestureDetectorState extends State<MatrixGestureDetector> {
  ValueUpdater<Offset> _translationUpdater =
      ValueUpdater((a, b) => b - a, Offset.zero);
  ValueUpdater<double> _scaleUpdater = ValueUpdater((a, b) => b / a, 0);
  ValueUpdater<Pair<Offset, int>> _doubleTapUpdater = ValueUpdater(
      ((Pair<Offset, int> a, Pair<Offset, int> b) =>
          Pair(b.left - a.left, b.right - a.right)),
      Pair(Offset.zero, 0));

  Offset? _lastPosition;
  VelocityTracker? _velocityTracker;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
  }

  void _onDoubleTap(Offset localPoint) {
    widget.onDoubleTap?.call(MatrixGestureDetectorDetails(
      position: localPoint,
      velocityTracker: _velocityTracker,
    ));
  }

  void _onScaleStart(ScaleStartDetails details) {
    _translationUpdater.value = details.localFocalPoint;
    _scaleUpdater.value = 1.0;

    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);
    widget.onStart?.call(MatrixGestureDetectorDetails(
      position: details.localFocalPoint,
    ));

    _startTime = DateTime.now();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _lastPosition = details.localFocalPoint;
    _velocityTracker?.addPosition(
      _startTime.difference(DateTime.now()),
      details.localFocalPoint,
    );

    Offset translationDelta = _translationUpdater.update(
      details.localFocalPoint,
    );
    final translationDeltaMatrix =
        MatrixGestureDetector.translateMatrix(translationDelta);

    double scaleDelta = _scaleUpdater.update(details.scale);
    final scaleDeltaMatrix = MatrixGestureDetector.scaleMatrix(
      scaleDelta,
      details.localFocalPoint,
    );

    widget.onUpdate?.call(MatrixGestureDetectorOnUpdateDetails(
      scale: details.scale,
      position: details.localFocalPoint,
      scaleMatrix: scaleDeltaMatrix,
      translateMatrix: translationDeltaMatrix,
      velocityTracker: _velocityTracker,
    ));
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (details.velocity == Velocity.zero) {
      final delta = _doubleTapUpdater.update(Pair(
          _translationUpdater.value, DateTime.now().millisecondsSinceEpoch));
      if (delta.right < kDoubleTapTimeout.inMilliseconds &&
          delta.left.distance < 40) {
        _onDoubleTap(_translationUpdater.value);
        _doubleTapUpdater.update(Pair(Offset.zero, 0));
      }
    } else {
      _doubleTapUpdater.update(Pair(Offset.zero, 0));
    }
    final lastPosition = _lastPosition;
    if (lastPosition != null) {
      widget.onEnd?.call(MatrixGestureDetectorDetails(
        position: lastPosition,
        velocityTracker: _velocityTracker,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: widget.child,
    );
  }
}

class Boxer {
  final Rect bounds;
  final Rect src;
  Rect? container;

  Boxer(this.bounds, this.src);

  void clamp(Matrix4 matrix, {bool restrictLowScale = true}) {
    final _container = MatrixUtils.transformRect(matrix, src);

    if (_container.contains(bounds.topLeft) &&
        _container.contains(bounds.bottomRight)) {
      return;
    }

    final lowWidth = _container.width < bounds.width;
    final lowHeight = _container.height < bounds.height;

    if (lowWidth || lowHeight) {
      vector.Vector3 t = vector.Vector3.zero();

      final scale = max(
          _container.width / bounds.width, _container.height / bounds.height);
      if (scale < 1) {
        if (restrictLowScale) {
          t.x = (bounds.width - src.width) / 2;
          t.y = (bounds.height - src.height) / 2;
          matrix.setFromTranslationRotationScale(
              t, vector.Quaternion.identity(), vector.Vector3(1, 1, 1));
        }
      } else {
        t.x =
            lowWidth ? (bounds.width - _container.width) / 2 : _container.left;
        t.y = lowHeight
            ? (bounds.height - _container.height) / 2
            : _container.top;

        matrix.setTranslation(t);
      }
    }

    if (!lowHeight) {
      if (_container.top > bounds.top) {
        matrix.leftTranslate(0.0, bounds.top - _container.top);
      }
      if (_container.bottom < bounds.bottom) {
        matrix.leftTranslate(0.0, bounds.bottom - _container.bottom);
      }
    }
    if (!lowWidth) {
      if (_container.left > bounds.left) {
        matrix.leftTranslate(bounds.left - _container.left, 0.0);
      }
      if (_container.right < bounds.right) {
        matrix.leftTranslate(bounds.right - _container.right, 0.0);
      }
    }

    container = _container;
  }

  void restrictHorizontalMoveAndScale(Matrix4 matrix) {
    final _container = MatrixUtils.transformRect(matrix, src);
    vector.Vector3 t = vector.Vector3.zero();
    t.x = (bounds.width - _container.width) / 2;
    t.y = _container.top;
    matrix.setFromTranslationRotationScale(
      t,
      vector.Quaternion.identity(),
      vector.Vector3(1, 1, 1),
    );
    container = _container;
  }

  void restrictVerticalMoveAndScale(Matrix4 matrix) {
    final _container = MatrixUtils.transformRect(matrix, src);
    vector.Vector3 t = vector.Vector3.zero();
    t.x = _container.left;
    t.y = (bounds.height - _container.height) / 2;
    matrix.setFromTranslationRotationScale(
      t,
      vector.Quaternion.identity(),
      vector.Vector3(1, 1, 1),
    );
    container = _container;
  }

  Rect getRect(Matrix4 matrix) {
    final _container = MatrixUtils.transformRect(matrix, src);
    container = _container;
    return _container;
  }

  void fit(Matrix4 matrix, Offset focalPoint, {double scaleDelta = 0}) {
    final _container = MatrixUtils.transformRect(matrix, src);

    final arContainer = _container.size.width / _container.size.height;
    final arBounds = bounds.size.width / bounds.size.height;
    double scale;

    if (arContainer > arBounds) {
      scale = bounds.size.height / _container.size.height;
    } else {
      scale = bounds.size.width / _container.size.width;
    }
    matrix.setFrom(
        MatrixGestureDetector.scaleMatrix(scale + scaleDelta, focalPoint));
    container = _container;
  }
}
