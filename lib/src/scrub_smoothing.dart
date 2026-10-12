import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// How the exposed progress follows the raw scroll-derived progress.
@immutable
sealed class ScrubSmoothing {
  const ScrubSmoothing();

  /// Progress mirrors the scroll position exactly.
  static const ScrubSmoothing none = _NoSmoothing();

  /// Exponential easing toward the target: after [timeConstant] the remaining
  /// distance has shrunk to ~37%. Frame-rate independent.
  const factory ScrubSmoothing.lerp([Duration timeConstant]) = LerpSmoothing;

  /// Critically- or under-damped spring toward the target.
  const factory ScrubSmoothing.spring({
    double stiffness,
    double damping,
    double mass,
  }) = SpringSmoothing;
}

class _NoSmoothing extends ScrubSmoothing {
  const _NoSmoothing();
}

/// See [ScrubSmoothing.lerp].
class LerpSmoothing extends ScrubSmoothing {
  /// Creates exponential smoothing with the given time constant.
  const LerpSmoothing([this.timeConstant = const Duration(milliseconds: 120)]);

  /// Time for the remaining distance to decay to 1/e.
  final Duration timeConstant;

  @override
  bool operator ==(Object other) =>
      other is LerpSmoothing && other.timeConstant == timeConstant;

  @override
  int get hashCode => timeConstant.hashCode;
}

/// See [ScrubSmoothing.spring].
class SpringSmoothing extends ScrubSmoothing {
  /// Creates spring smoothing.
  const SpringSmoothing({
    this.stiffness = 180,
    this.damping = 24,
    this.mass = 1,
  });

  /// Spring constant.
  final double stiffness;

  /// Damping coefficient.
  final double damping;

  /// Mass of the simulated body.
  final double mass;

  /// The spring description used by the simulation.
  SpringDescription get description =>
      SpringDescription(mass: mass, stiffness: stiffness, damping: damping);

  @override
  bool operator ==(Object other) =>
      other is SpringSmoothing &&
      other.stiffness == stiffness &&
      other.damping == damping &&
      other.mass == mass;

  @override
  int get hashCode => Object.hash(stiffness, damping, mass);
}
