import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'scene_controller.dart';
import 'scene_geometry.dart';
import 'scene_markers.dart';
import 'scene_position.dart';

/// Box version of the scene for use inside `ListView`, `Column` and other
/// box scrollables. Measures its position with the enclosing
/// [RenderAbstractViewport] and translates the child while pinned.
class RenderScrollSceneBox extends RenderShiftedBox {
  /// Creates the render box.
  RenderScrollSceneBox({
    required SceneController controller,
    required AxisDirection axisDirection,
    required ScenePosition start,
    required ScenePosition end,
    double? pinExtent,
    double? pinnedExtent,
    double? fallbackViewportExtent,
    SceneMarkers? markers,
    RenderBox? child,
  }) : _controller = controller,
       _axisDirection = axisDirection,
       _start = start,
       _end = end,
       _pinExtent = pinExtent,
       _pinnedExtent = pinnedExtent,
       _fallbackViewportExtent = fallbackViewportExtent,
       _markers = markers,
       super(child);

  SceneController _controller;

  /// Receives geometry updates.
  SceneController get controller => _controller;
  set controller(SceneController value) {
    if (identical(value, _controller)) return;
    if (attached) _controller.removeListener(_onProgress);
    _controller = value;
    if (attached) _controller.addListener(_onProgress);
    markNeedsPaint();
  }

  AxisDirection _axisDirection;

  /// Scroll direction of the enclosing scrollable.
  AxisDirection get axisDirection => _axisDirection;
  set axisDirection(AxisDirection value) {
    if (value == _axisDirection) return;
    _axisDirection = value;
    markNeedsLayout();
  }

  ScenePosition _start;

  /// Start trigger for unpinned scenes.
  ScenePosition get start => _start;
  set start(ScenePosition value) {
    if (value == _start) return;
    _start = value;
    markNeedsPaint();
  }

  ScenePosition _end;

  /// End trigger for unpinned scenes.
  ScenePosition get end => _end;
  set end(ScenePosition value) {
    if (value == _end) return;
    _end = value;
    markNeedsPaint();
  }

  double? _pinExtent;

  /// Pin distance; null disables pinning.
  double? get pinExtent => _pinExtent;
  set pinExtent(double? value) {
    if (value == _pinExtent) return;
    _pinExtent = value;
    markNeedsLayout();
  }

  double? _pinnedExtent;

  /// Main-axis extent of the child while pinned; defaults to the viewport.
  double? get pinnedExtent => _pinnedExtent;
  set pinnedExtent(double? value) {
    if (value == _pinnedExtent) return;
    _pinnedExtent = value;
    markNeedsLayout();
  }

  double? _fallbackViewportExtent;

  /// Viewport extent used when the enclosing viewport cannot be measured.
  double? get fallbackViewportExtent => _fallbackViewportExtent;
  set fallbackViewportExtent(double? value) {
    if (value == _fallbackViewportExtent) return;
    _fallbackViewportExtent = value;
    markNeedsLayout();
  }

  SceneMarkers? _markers;

  /// Debug marker style; null hides markers.
  SceneMarkers? get markers => _markers;
  set markers(SceneMarkers? value) {
    if (value == _markers) return;
    _markers = value;
    _markerPainter?.dispose();
    _markerPainter = null;
    markNeedsPaint();
  }

  SceneMarkerPainter? _markerPainter;
  double _childExtent = 0;
  double _viewportExtent = 0;

  Axis get _axis => axisDirectionToAxis(_axisDirection);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(_onProgress);
  }

  @override
  void detach() {
    _controller.removeListener(_onProgress);
    super.detach();
  }

  void _onProgress() {
    if (_pinExtent != null || _markers != null) markNeedsPaint();
  }

  double? _measureViewport(RenderAbstractViewport? viewport) {
    if (viewport is! RenderBox) return null;
    final box = viewport as RenderBox;
    final size =
        box.hasSize
            ? box.size
            : (box.constraints.hasBoundedHeight &&
                    box.constraints.hasBoundedWidth
                ? box.constraints.biggest
                : null);
    if (size == null) return null;
    return switch (_axis) {
      Axis.vertical => size.height,
      Axis.horizontal => size.width,
    };
  }

  @override
  void performLayout() {
    final child = this.child;
    final pin = _pinExtent;
    _viewportExtent =
        _measureViewport(RenderAbstractViewport.maybeOf(this)) ??
        _fallbackViewportExtent ??
        0;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    if (pin != null) {
      final extent = _pinnedExtent ?? _viewportExtent;
      final childConstraints = switch (_axis) {
        Axis.vertical => BoxConstraints.tightFor(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          height: extent,
        ),
        Axis.horizontal => BoxConstraints.tightFor(
          width: extent,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
        ),
      };
      child.layout(childConstraints, parentUsesSize: true);
      _childExtent = extent;
      size = constraints.constrain(switch (_axis) {
        Axis.vertical => Size(child.size.width, extent + pin),
        Axis.horizontal => Size(extent + pin, child.size.height),
      });
    } else {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
      _childExtent = switch (_axis) {
        Axis.vertical => size.height,
        Axis.horizontal => size.width,
      };
    }
    (child.parentData! as BoxParentData).offset = Offset.zero;
  }

  double? _leadingEdge() {
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport == null) return null;
    final reveal = viewport.getOffsetToReveal(this, 0).offset;
    return reveal - _controller.pixels;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final leading = _leadingEdge();
    final pin = _pinExtent;
    var shift = 0.0;
    if (leading != null) {
      final reversed = axisDirectionIsReversed(_axisDirection);
      shift = (-leading).clamp(0.0, pin ?? 0.0);
      final data = child.parentData! as BoxParentData;
      final main = reversed ? (pin ?? 0) - shift : shift;
      data.offset = switch (_axis) {
        Axis.vertical => Offset(0, main),
        Axis.horizontal => Offset(main, 0),
      };
      _controller.updateGeometry(
        range: SceneGeometry.range(
          pixels: _controller.pixels,
          leadingEdge: leading,
          elementExtent: _childExtent,
          viewportExtent: _viewportExtent,
          pinExtent: pin,
          start: _start,
          end: _end,
        ),
        fallbackPixels: _controller.pixels,
        pinned: pin != null,
      );
    }
    super.paint(context, offset);
    final style = _markers;
    if (style == null || leading == null) return;
    final painter = _markerPainter ??= SceneMarkerPainter(style);
    final reversed = axisDirectionIsReversed(_axisDirection);
    final mainSize = switch (_axis) {
      Axis.vertical => size.height,
      Axis.horizontal => size.width,
    };
    final crossSize = switch (_axis) {
      Axis.vertical => size.width,
      Axis.horizontal => size.height,
    };
    final layout = SceneGeometry.markers(
      axisDirection: _axisDirection,
      crossExtent: crossSize,
      contentStart: 0,
      viewportOrigin: -leading,
      elementExtent: _childExtent,
      viewportExtent: _viewportExtent,
      pinExtent: pin,
      start: _start,
      end: _end,
      progress: _controller.rawProgress,
    );
    final paintOrigin =
        reversed
            ? switch (_axis) {
              Axis.vertical => offset + Offset(0, mainSize),
              Axis.horizontal => offset + Offset(mainSize, 0),
            }
            : offset;
    painter.paint(context.canvas, paintOrigin, layout);
  }

  @override
  void dispose() {
    _markerPainter?.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('pinExtent', _pinExtent));
    properties.add(DoubleProperty('viewportExtent', _viewportExtent));
    properties.add(
      DoubleProperty('progress', math.max(0, _controller.rawProgress)),
    );
  }
}
