import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Snap configuration: when the user stops scrolling inside a scene, the
/// scroll position animates to the nearest progress in [points].
@immutable
class SceneSnap {
  /// Creates a snap configuration.
  const SceneSnap({
    required this.points,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutCubic,
    this.tolerance = 0.002,
  });

  /// Progress values (0..1) to settle on.
  final List<double> points;

  /// Duration of the settle animation.
  final Duration duration;

  /// Curve of the settle animation.
  final Curve curve;

  /// Progress distance below which the scene is considered already snapped.
  final double tolerance;

  /// Nearest snap point to [progress].
  double nearest(double progress) {
    var best = points.first;
    var bestDistance = (progress - best).abs();
    for (final p in points.skip(1)) {
      final d = (progress - p).abs();
      if (d < bestDistance) {
        best = p;
        bestDistance = d;
      }
    }
    return best;
  }

  /// Whether [progress] already sits on a snap point.
  bool isSettled(double progress) =>
      (progress - nearest(progress)).abs() <= tolerance;
}
