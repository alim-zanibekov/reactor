import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../common/types.dart';
import '../common/value-updater.dart';

class MatrixGestureDetectorDetails {
  final Matrix4 translateMatrix;
  final Matrix4 scaleMatrix;
  final Offset position;
  final double scale;
  final VelocityTracker _velocityTracker;

  const MatrixGestureDetectorDetails(
      {this.position,
      this.scale,
      velocityTracker,
      this.translateMatrix,
      this.scaleMatrix})
      : this._velocityTracker = velocityTracker;

  VelocityEstimate get velocityEstimate =>
      _velocityTracker.getVelocityEstimate();
}

typedef GestureDetectorCallback<T> = void Function(
    MatrixGestureDetectorDetails details);

class MatrixGestureDetector extends StatefulWidget {
  final Widget child;
  final GestureDetectorCallback onStart;
  final GestureDetectorCallback onUpdate;
  final GestureDetectorCallback onEnd;
  final GestureDetectorCallback onDoubleTap;

  const MatrixGestureDetector(
      {Key key,
      @required this.child,
      this.onStart,
      this.onUpdate,
      this.onEnd,
      this.onDoubleTap})
      : super(key: key);

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
  ValueUpdater<Offset> _translationUpdater = ValueUpdater((a, b) => b - a);
  ValueUpdater<double> _scaleUpdater = ValueUpdater((a, b) => b / a);
  ValueUpdater<Pair<Offset, int>> _doubleTapUpdater = ValueUpdater(
      (a, b) => Pair(b.left - a.left, b.right - a.right),
      value: Pair(Offset.zero, 0));

  Offset _lastPosition;
  VelocityTracker _velocityTracker;

  DateTime _startTime;

  @override
  void initState() {
    super.initState();
  }

  void _onDoubleTap(Offset localPoint) {
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap(MatrixGestureDetectorDetails(
        position: localPoint,
        velocityTracker: _velocityTracker,
      ));
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _translationUpdater.value = details.localFocalPoint;
    _scaleUpdater.value = 1.0;

    _velocityTracker = VelocityTracker();
    if (widget.onStart != null) {
      widget.onStart(MatrixGestureDetectorDetails(
        position: details.localFocalPoint,
      ));
    }

    _startTime = DateTime.now();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _lastPosition = details.localFocalPoint;
    _velocityTracker.addPosition(
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

    if (widget.onUpdate != null) {
      widget.onUpdate(
        MatrixGestureDetectorDetails(
            scale: details.scale,
            position: details.localFocalPoint,
            scaleMatrix: scaleDeltaMatrix,
            translateMatrix: translationDeltaMatrix,
            velocityTracker: _velocityTracker),
      );
    }
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

    if (widget.onEnd != null) {
      widget.onEnd(MatrixGestureDetectorDetails(
        position: _lastPosition,
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
        child: widget.child);
  }
}

class Boxer {
  final Rect bounds;
  final Rect src;
  Rect container;

  Boxer(this.bounds, this.src);

  void clamp(Matrix4 matrix) {
    container = MatrixUtils.transformRect(matrix, src);

    if (container.contains(bounds.topLeft) &&
        container.contains(bounds.bottomRight)) {
      return;
    }

    final lowWidth = container.width < bounds.width;
    final lowHeight = container.height < bounds.height;

    if (lowWidth || lowHeight) {
      vector.Vector3 t = vector.Vector3.zero();

      final scale =
          max(container.width / bounds.width, container.height / bounds.height);
      if (scale < 1) {
        t.x = (bounds.width - src.width) / 2;
        t.y = (bounds.height - src.height) / 2;
        matrix.setFromTranslationRotationScale(
            t, vector.Quaternion.identity(), vector.Vector3(1, 1, 0));
      } else {
        t.x = lowWidth ? (bounds.width - container.width) / 2 : container.left;
        t.y =
            lowHeight ? (bounds.height - container.height) / 2 : container.top;

        matrix.setTranslation(t);
      }
    }

    if (!lowHeight) {
      if (container.top > bounds.top) {
        matrix.leftTranslate(0.0, bounds.top - container.top);
      }
      if (container.bottom < bounds.bottom) {
        matrix.leftTranslate(0.0, bounds.bottom - container.bottom);
      }
    }
    if (!lowWidth) {
      if (container.left > bounds.left) {
        matrix.leftTranslate(bounds.left - container.left, 0.0);
      }
      if (container.right < bounds.right) {
        matrix.leftTranslate(bounds.right - container.right, 0.0);
      }
    }
  }

  void restrictHorizontalMoveAndScale(Matrix4 matrix) {
    container = MatrixUtils.transformRect(matrix, src);
    vector.Vector3 t = vector.Vector3.zero();
    t.x = (bounds.width - container.width) / 2;
    t.y = container.top;
    matrix.setFromTranslationRotationScale(
      t,
      vector.Quaternion.identity(),
      vector.Vector3(1, 1, 0),
    );
  }

  void restrictVerticalMoveAndScale(Matrix4 matrix) {
    container = MatrixUtils.transformRect(matrix, src);
    vector.Vector3 t = vector.Vector3.zero();
    t.x = container.left;
    t.y = (bounds.height - container.height) / 2;
    matrix.setFromTranslationRotationScale(
      t,
      vector.Quaternion.identity(),
      vector.Vector3(1, 1, 0),
    );
  }

  Rect getRect(Matrix4 matrix) {
    container = MatrixUtils.transformRect(matrix, src);
    return container;
  }

  void fit(Matrix4 matrix, Offset focalPoint, { double scaleDelta = 0 }) {
    container = MatrixUtils.transformRect(matrix, src);

    final arContainer = container.size.width / container.size.height;
    final arBounds = bounds.size.width / bounds.size.height;
    double scale;

    if (arContainer > arBounds) {
      scale = bounds.size.height / container.size.height;
    } else {
      scale = bounds.size.width / container.size.width;
    }
    matrix.setFrom(MatrixGestureDetector.scaleMatrix(scale + scaleDelta, focalPoint));
  }
}
