import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'scene_controller.dart';
import 'scene_geometry.dart';
import 'scene_markers.dart';
import 'scene_position.dart';

/// Sliver that optionally pins its box child for [pinExtent] pixels of
/// scroll and reports progress to a [SceneController].
class RenderSliverScrollScene extends RenderSliverSingleBoxAdapter {
  /// Creates the render sliver.
  RenderSliverScrollScene({
    required SceneController controller,
    required ScenePosition start,
    required ScenePosition end,
    double? pinExtent,
    double? pinnedExtent,
    SceneMarkers? markers,
    super.child,
  }) : _controller = controller,
       _start = start,
       _end = end,
       _pinExtent = pinExtent,
       _pinnedExtent = pinnedExtent,
       _markers = markers;

  SceneController _controller;

  /// Receives geometry updates.
  SceneController get controller => _controller;
  set controller(SceneController value) {
    if (identical(value, _controller)) return;
    if (attached) _controller.removeListener(_onProgress);
    _controller = value;
    if (attached) _controller.addListener(_onProgress);
    markNeedsLayout();
  }

  ScenePosition _start;

  /// Start trigger for unpinned scenes.
  ScenePosition get start => _start;
  set start(ScenePosition value) {
    if (value == _start) return;
    _start = value;
    markNeedsLayout();
  }

  ScenePosition _end;

  /// End trigger for unpinned scenes.
  ScenePosition get end => _end;
  set end(ScenePosition value) {
    if (value == _end) return;
    _end = value;
    markNeedsLayout();
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
  double _shift = 0;
  double _childExtent = 0;
  double _leadingEdge = 0;

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
    if (_markers != null) markNeedsPaint();
  }

  @override
  void performLayout() {
    final c = constraints;
    final child = this.child;
    final pin = _pinExtent;
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    if (pin != null) {
      final extent = _pinnedExtent ?? c.viewportMainAxisExtent;
      child.layout(
        c.asBoxConstraints(minExtent: extent, maxExtent: extent),
        parentUsesSize: true,
      );
      _childExtent = extent;
    } else {
      child.layout(c.asBoxConstraints(), parentUsesSize: true);
      _childExtent = switch (c.axis) {
        Axis.vertical => child.size.height,
        Axis.horizontal => child.size.width,
      };
    }
    final pinExtent = pin ?? 0;
    _shift = c.scrollOffset.clamp(0.0, pinExtent);
    final from = _shift;
    final to = from + _childExtent;
    final painted = calculatePaintOffset(c, from: from, to: to);
    final cached = calculateCacheOffset(c, from: from, to: to);
    final total = _childExtent + pinExtent;
    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: painted,
      cacheExtent: cached,
      maxPaintExtent: total,
      hitTestExtent: painted,
      hasVisualOverflow: to > c.remainingPaintExtent || c.scrollOffset > 0,
    );
    _positionChild(child);
    _leadingEdge = _resolveLeadingEdge(c);
    _controller.updateGeometry(
      range: SceneGeometry.range(
        pixels:
            _controller.position?.pixels ??
            (c.precedingScrollExtent + c.scrollOffset),
        leadingEdge: _leadingEdge,
        elementExtent: _childExtent,
        viewportExtent: c.viewportMainAxisExtent,
        pinExtent: pin,
        start: _start,
        end: _end,
      ),
      fallbackPixels: c.precedingScrollExtent + c.scrollOffset,
      pinned: pin != null,
    );
  }

  double _resolveLeadingEdge(SliverConstraints c) {
    if (c.scrollOffset > 0) return -c.scrollOffset;
    final visible = c.viewportMainAxisExtent - c.remainingPaintExtent;
    if (c.remainingPaintExtent > 0) return visible;
    final position = _controller.position;
    if (position != null && position.hasPixels) {
      final byScroll = c.precedingScrollExtent - position.pixels;
      if (byScroll >= visible) return byScroll;
    }
    return visible;
  }

  void _positionChild(RenderBox child) {
    final c = constraints;
    final data = child.parentData! as SliverPhysicalParentData;
    final main = _shift - c.scrollOffset;
    final g = geometry!;
    data.paintOffset = switch (applyGrowthDirectionToAxisDirection(
      c.axisDirection,
      c.growthDirection,
    )) {
      AxisDirection.down => Offset(0, main),
      AxisDirection.right => Offset(main, 0),
      AxisDirection.up => Offset(0, g.paintExtent - main - _childExtent),
      AxisDirection.left => Offset(g.paintExtent - main - _childExtent, 0),
    };
  }

  @override
  double childMainAxisPosition(RenderBox child) =>
      _shift - constraints.scrollOffset;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final style = _markers;
    if (style == null || child == null) return;
    final c = constraints;
    final painter = _markerPainter ??= SceneMarkerPainter(style);
    final origin = _leadingEdge + math.max(0.0, c.scrollOffset);
    final layout = SceneGeometry.markers(
      axisDirection: applyGrowthDirectionToAxisDirection(
        c.axisDirection,
        c.growthDirection,
      ),
      crossExtent: c.crossAxisExtent,
      contentStart: -math.max(0.0, c.scrollOffset),
      viewportOrigin: -origin,
      elementExtent: _childExtent,
      viewportExtent: c.viewportMainAxisExtent,
      pinExtent: _pinExtent,
      start: _start,
      end: _end,
      progress: _controller.rawProgress,
    );
    final reversed = axisDirectionIsReversed(layout.axisDirection);
    final paintOrigin =
        reversed
            ? switch (c.axis) {
              Axis.vertical => offset + Offset(0, geometry!.paintExtent),
              Axis.horizontal => offset + Offset(geometry!.paintExtent, 0),
            }
            : offset;
    painter.paint(context.canvas, paintOrigin, layout);
  }

  @override
  void dispose() {
    _markerPainter?.dispose();
    super.dispose();
  }
}
