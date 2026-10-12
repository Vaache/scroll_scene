import 'package:flutter/rendering.dart';

import 'scene_markers.dart';
import 'scene_position.dart';

/// Shared geometry resolution for the sliver and box render objects.
class SceneGeometry {
  SceneGeometry._();

  /// Resolves the scroll range for a scene.
  static SceneRange range({
    required double pixels,
    required double leadingEdge,
    required double elementExtent,
    required double viewportExtent,
    required double? pinExtent,
    required ScenePosition start,
    required ScenePosition end,
  }) =>
      pinExtent != null
          ? SceneRange.pinned(
            pixels: pixels,
            leadingEdge: leadingEdge,
            pinExtent: pinExtent,
          )
          : SceneRange.triggered(
            pixels: pixels,
            leadingEdge: leadingEdge,
            elementExtent: elementExtent,
            viewportExtent: viewportExtent,
            start: start,
            end: end,
          );

  /// Builds marker layout data. All main-axis values are relative to the
  /// paint origin, where [contentStart] is the element's leading edge and
  /// [viewportOrigin] is the viewport's leading edge.
  static SceneMarkerLayout markers({
    required AxisDirection axisDirection,
    required double crossExtent,
    required double contentStart,
    required double viewportOrigin,
    required double elementExtent,
    required double viewportExtent,
    required double? pinExtent,
    required ScenePosition start,
    required ScenePosition end,
    required double progress,
  }) {
    final pinned = pinExtent != null;
    return SceneMarkerLayout(
      axisDirection: axisDirection,
      crossExtent: crossExtent,
      contentStart: contentStart,
      contentExtent: elementExtent,
      triggerStart:
          pinned ? contentStart : contentStart + start.element * elementExtent,
      triggerEnd:
          pinned
              ? contentStart + pinExtent
              : contentStart + end.element * elementExtent,
      scrollerStart:
          viewportOrigin + (pinned ? 0 : start.viewport * viewportExtent),
      scrollerEnd:
          viewportOrigin + (pinned ? 0 : end.viewport * viewportExtent),
      pinExtent: pinExtent ?? 0,
      progress: progress,
    );
  }
}
