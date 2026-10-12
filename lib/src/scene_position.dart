import 'package:flutter/foundation.dart';

/// Where an unpinned scene's progress starts or ends, expressed as the
/// moment a point on the element reaches a point in the viewport.
///
/// `ScenePosition.top(0.8)` is GSAP's `"top 80%"`: the element's top edge
/// crossing 80% of the viewport height (measured from the leading edge).
@immutable
class ScenePosition {
  /// Creates a position from explicit anchors, both in the range 0..1.
  const ScenePosition({required this.element, required this.viewport})
    : assert(element >= 0 && element <= 1),
      assert(viewport >= 0 && viewport <= 1);

  /// The element's leading edge reaching [viewport] of the viewport extent.
  const ScenePosition.top(double viewport)
    : this(element: 0, viewport: viewport);

  /// The element's centre reaching [viewport] of the viewport extent.
  const ScenePosition.center(double viewport)
    : this(element: 0.5, viewport: viewport);

  /// The element's trailing edge reaching [viewport] of the viewport extent.
  const ScenePosition.bottom(double viewport)
    : this(element: 1, viewport: viewport);

  /// Fraction of the element's main-axis extent, 0 = leading, 1 = trailing.
  final double element;

  /// Fraction of the viewport's main-axis extent, 0 = leading, 1 = trailing.
  final double viewport;

  /// Signed distance from the element anchor to the viewport anchor, given
  /// the element's current leading edge relative to the viewport's leading
  /// edge. Positive once the anchor has been passed in the forward direction.
  double distance({
    required double leadingEdge,
    required double elementExtent,
    required double viewportExtent,
  }) => viewport * viewportExtent - (leadingEdge + element * elementExtent);

  @override
  bool operator ==(Object other) =>
      other is ScenePosition &&
      other.element == element &&
      other.viewport == viewport;

  @override
  int get hashCode => Object.hash(element, viewport);

  @override
  String toString() => 'ScenePosition(element: $element, viewport: $viewport)';
}

/// The scroll range, in scroll-offset pixels, over which a scene's progress
/// runs from 0 to 1.
@immutable
class SceneRange {
  /// Creates a range starting at [start] pixels and spanning [extent] pixels.
  const SceneRange({required this.start, required this.extent});

  /// Scroll offset at which progress is 0.
  final double start;

  /// Scroll distance over which progress reaches 1. Always positive.
  final double extent;

  /// Scroll offset at which progress is 1.
  double get end => start + extent;

  /// Progress for a given scroll offset, clamped to 0..1.
  double progressAt(double pixels) =>
      extent <= 0
          ? (pixels >= start ? 1 : 0)
          : ((pixels - start) / extent).clamp(0.0, 1.0);

  /// Scroll offset at which [progress] is reached.
  double pixelsAt(double progress) => start + progress * extent;

  /// Resolves the range for a pinned scene whose leading edge is currently at
  /// [leadingEdge] relative to the viewport's leading edge.
  static SceneRange pinned({
    required double pixels,
    required double leadingEdge,
    required double pinExtent,
  }) => SceneRange(start: pixels + leadingEdge, extent: pinExtent);

  /// Resolves the range for an unpinned scene from its [start] and [end]
  /// trigger positions.
  static SceneRange triggered({
    required double pixels,
    required double leadingEdge,
    required double elementExtent,
    required double viewportExtent,
    required ScenePosition start,
    required ScenePosition end,
  }) {
    final dStart = start.distance(
      leadingEdge: leadingEdge,
      elementExtent: elementExtent,
      viewportExtent: viewportExtent,
    );
    final dEnd = end.distance(
      leadingEdge: leadingEdge,
      elementExtent: elementExtent,
      viewportExtent: viewportExtent,
    );
    return SceneRange(start: pixels - dStart, extent: (dStart - dEnd).abs());
  }

  @override
  bool operator ==(Object other) =>
      other is SceneRange && other.start == start && other.extent == extent;

  @override
  int get hashCode => Object.hash(start, extent);

  @override
  String toString() => 'SceneRange(start: $start, extent: $extent)';
}
