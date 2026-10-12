import 'dart:ui' show Color, Offset, Rect, Size, lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A value the timeline passes through at [offset] (0..1 of scene progress).
///
/// [curve] eases the segment that *ends* at this keyframe.
@immutable
class Keyframe<T> {
  /// Creates a keyframe.
  const Keyframe(this.offset, this.value, {this.curve = Curves.linear})
    : assert(offset >= 0 && offset <= 1);

  /// Position on the 0..1 timeline.
  final double offset;

  /// Value at [offset].
  final T value;

  /// Easing applied between the previous keyframe and this one.
  final Curve curve;

  @override
  String toString() => 'Keyframe($offset, $value)';
}

/// Interpolates between two values of type [T].
typedef SceneLerp<T> = T Function(T a, T b, double t);

/// Keyframed values over scene progress. It is an [Animatable], so
/// `scene.progress.drive(timeline)` yields an `Animation<T>`.
///
/// Before the first keyframe the first value holds; after the last keyframe
/// the last value holds.
class SceneTimeline<T> extends Animatable<T> {
  /// Creates a timeline with a custom interpolator. Keyframes are sorted by
  /// offset.
  SceneTimeline(List<Keyframe<T>> keyframes, {required SceneLerp<T> lerp})
    : assert(keyframes.isNotEmpty),
      _lerp = lerp,
      keyframes = List.unmodifiable(
        [...keyframes]..sort((a, b) => a.offset.compareTo(b.offset)),
      );

  /// Doubles.
  static SceneTimeline<double> number(List<Keyframe<double>> keyframes) =>
      SceneTimeline(keyframes, lerp: (a, b, t) => lerpDouble(a, b, t)!);

  /// Offsets.
  static SceneTimeline<Offset> offset(List<Keyframe<Offset>> keyframes) =>
      SceneTimeline(keyframes, lerp: (a, b, t) => Offset.lerp(a, b, t)!);

  /// Colors.
  static SceneTimeline<Color> color(List<Keyframe<Color>> keyframes) =>
      SceneTimeline(keyframes, lerp: (a, b, t) => Color.lerp(a, b, t)!);

  /// Sizes.
  static SceneTimeline<Size> size(List<Keyframe<Size>> keyframes) =>
      SceneTimeline(keyframes, lerp: (a, b, t) => Size.lerp(a, b, t)!);

  /// Rects.
  static SceneTimeline<Rect> rect(List<Keyframe<Rect>> keyframes) =>
      SceneTimeline(keyframes, lerp: (a, b, t) => Rect.lerp(a, b, t)!);

  /// Alignments.
  static SceneTimeline<Alignment> alignment(
    List<Keyframe<Alignment>> keyframes,
  ) => SceneTimeline(keyframes, lerp: (a, b, t) => Alignment.lerp(a, b, t)!);

  /// Edge insets.
  static SceneTimeline<EdgeInsets> edgeInsets(
    List<Keyframe<EdgeInsets>> keyframes,
  ) => SceneTimeline(keyframes, lerp: (a, b, t) => EdgeInsets.lerp(a, b, t)!);

  /// Keyframes sorted by offset.
  final List<Keyframe<T>> keyframes;
  final SceneLerp<T> _lerp;

  @override
  T transform(double t) {
    final first = keyframes.first;
    if (t <= first.offset) return first.value;
    for (var i = 1; i < keyframes.length; i++) {
      final k = keyframes[i];
      if (t <= k.offset) {
        final prev = keyframes[i - 1];
        final span = k.offset - prev.offset;
        if (span <= 0) return k.value;
        final local = k.curve.transform((t - prev.offset) / span);
        return _lerp(prev.value, k.value, local);
      }
    }
    return keyframes.last.value;
  }

  @override
  String toString() => 'SceneTimeline($keyframes)';
}

/// Where a staggered sequence begins.
enum StaggerFrom {
  /// Item 0 first.
  start,

  /// Last item first.
  end,

  /// Middle item first, spreading outward.
  center,
}

/// Maps scene progress to the sub-progress of item [index] out of [count],
/// offsetting each item's window by [each] so items animate one after the
/// other. Use as `scene.progress.drive(Stagger(index: i, count: n))`.
class Stagger extends Animatable<double> {
  /// Creates a stagger for one item.
  ///
  /// With [each] null, items are spread evenly so the last window ends at 1
  /// and each window spans [duration] of the timeline (default: one share).
  const Stagger({
    required this.index,
    required this.count,
    this.each,
    this.duration,
    this.from = StaggerFrom.start,
    this.curve = Curves.linear,
  }) : assert(count > 0),
       assert(index >= 0 && index < count);

  /// Item position.
  final int index;

  /// Total items.
  final int count;

  /// Delay between consecutive item starts, as a fraction of the timeline.
  final double? each;

  /// Length of each item's window as a fraction of the timeline.
  final double? duration;

  /// Ordering.
  final StaggerFrom from;

  /// Easing inside the item's window.
  final Curve curve;

  /// The item's `[start, end]` window on the timeline.
  Interval get interval {
    final order = switch (from) {
      StaggerFrom.start => index,
      StaggerFrom.end => count - 1 - index,
      StaggerFrom.center => ((count - 1) / 2 - index).abs().round(),
    };
    final slots = switch (from) {
      StaggerFrom.center => (count / 2).ceil(),
      _ => count,
    };
    final len =
        duration ??
        (each != null ? (1 - each! * (slots - 1)).clamp(0.05, 1.0) : 1 / slots);
    final step = each ?? (slots > 1 ? (1 - len) / (slots - 1) : 0.0);
    final start = (order * step).clamp(0.0, 1.0);
    final end = (start + len).clamp(start, 1.0);
    return Interval(start, end, curve: curve);
  }

  @override
  double transform(double t) => interval.transform(t);

  @override
  String toString() => 'Stagger($index/$count, $interval)';
}
