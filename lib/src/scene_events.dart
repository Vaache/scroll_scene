import 'package:flutter/foundation.dart';

/// Direction the scroll is moving through a scene.
enum SceneDirection {
  /// Progress increasing.
  forward,

  /// Progress decreasing.
  backward,
}

/// Boundary events a scene emits as raw progress crosses 0 and 1.
enum SceneEvent {
  /// Progress left 0 going forward.
  enter,

  /// Progress reached 1 going forward.
  leave,

  /// Progress left 1 going backward.
  enterBack,

  /// Progress reached 0 going backward.
  leaveBack,
}

/// Pure state machine turning a stream of raw progress values into
/// [SceneEvent]s and a [SceneDirection].
class SceneStateMachine {
  /// Creates a machine; the first [update] seeds the state without events.
  SceneStateMachine();

  double? _last;
  SceneDirection _direction = SceneDirection.forward;

  /// Last direction of travel.
  SceneDirection get direction => _direction;

  /// Whether the scene is active (0 < progress < 1, or on an edge the user
  /// is inside of).
  bool get isActive => _last != null && _last! > 0 && _last! < 1;

  /// Feeds a new raw progress value and returns the events it caused, in
  /// order.
  List<SceneEvent> update(double progress) {
    final last = _last;
    _last = progress;
    if (last == null || last == progress) return const [];
    _direction =
        progress > last ? SceneDirection.forward : SceneDirection.backward;
    final events = <SceneEvent>[];
    if (_direction == SceneDirection.forward) {
      if (last <= 0 && progress > 0) events.add(SceneEvent.enter);
      if (last < 1 && progress >= 1) events.add(SceneEvent.leave);
    } else {
      if (last >= 1 && progress < 1) events.add(SceneEvent.enterBack);
      if (last > 0 && progress <= 0) events.add(SceneEvent.leaveBack);
    }
    return events;
  }

  /// Resets to the unseeded state.
  void reset() {
    _last = null;
    _direction = SceneDirection.forward;
  }

  @override
  String toString() =>
      '${describeIdentity(this)}(last: $_last, direction: $_direction)';
}
