import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'scene_events.dart';
import 'scene_position.dart';
import 'scene_snap.dart';
import 'scrub_smoothing.dart';

/// Callbacks a scene emits as the user scrolls through it.
@immutable
class SceneCallbacks {
  /// Creates a callback bundle; every field is optional.
  const SceneCallbacks({
    this.onEnter,
    this.onLeave,
    this.onEnterBack,
    this.onLeaveBack,
    this.onProgress,
  });

  /// Raw progress left 0 scrolling forward.
  final VoidCallback? onEnter;

  /// Raw progress reached 1 scrolling forward.
  final VoidCallback? onLeave;

  /// Raw progress left 1 scrolling backward.
  final VoidCallback? onEnterBack;

  /// Raw progress reached 0 scrolling backward.
  final VoidCallback? onLeaveBack;

  /// Raw (unsmoothed) progress changed.
  final ValueChanged<double>? onProgress;

  /// Whether no callback is set.
  bool get isEmpty =>
      onEnter == null &&
      onLeave == null &&
      onEnterBack == null &&
      onLeaveBack == null &&
      onProgress == null;

  void _dispatch(SceneEvent event) {
    switch (event) {
      case SceneEvent.enter:
        onEnter?.call();
      case SceneEvent.leave:
        onLeave?.call();
      case SceneEvent.enterBack:
        onEnterBack?.call();
      case SceneEvent.leaveBack:
        onLeaveBack?.call();
    }
  }
}

/// Drives a scene: turns scroll offsets into a 0..1 [progress] animation,
/// smooths it, fires boundary callbacks and performs snapping.
///
/// Normally created by [SliverScrollScene] / [ScrollScene]; pass your own
/// instance to read the same progress from widgets outside the scene.
class SceneController extends ChangeNotifier {
  /// Creates a detached controller.
  SceneController();

  final _SceneProgress _progress = _SceneProgress();
  final SceneStateMachine _machine = SceneStateMachine();

  ScrollPosition? _position;
  TickerProvider? _vsync;
  Ticker? _ticker;
  ScrubSmoothing _smoothing = ScrubSmoothing.none;
  SceneSnap? _snap;
  SceneCallbacks _callbacks = const SceneCallbacks();
  bool _reduceMotion = false;

  SceneRange? _range;
  double _raw = 0;
  double _fallbackPixels = 0;
  bool _pinned = false;
  bool _notifyScheduled = false;
  bool _snapping = false;

  Duration? _lastTick;
  SpringSimulation? _spring;
  Duration _springStart = Duration.zero;
  double _velocity = 0;

  /// Smoothed progress in 0..1. Drive tweens and [AnimatedBuilder]s with it.
  Animation<double> get progress => _progress;

  /// Scroll-exact progress in 0..1, before smoothing.
  double get rawProgress => _raw;

  /// Direction of the last progress change.
  SceneDirection get direction => _machine.direction;

  /// Whether raw progress is strictly between 0 and 1.
  bool get isActive => _machine.isActive;

  /// Whether this scene pins its content.
  bool get isPinned => _pinned;

  /// The scroll range the scene currently maps onto, once laid out.
  SceneRange? get range => _range;

  /// The scroll position the controller follows, if attached.
  ScrollPosition? get position => _position;

  /// Current scroll offset: the attached position's pixels, or the layout
  /// derived fallback when no position is available.
  double get pixels => _position?.pixels ?? _fallbackPixels;

  /// Connects the controller to a scroll position and configures behaviour.
  /// Safe to call repeatedly; re-attaching to the same position only updates
  /// configuration.
  void attach({
    required ScrollPosition? position,
    required TickerProvider? vsync,
    ScrubSmoothing smoothing = ScrubSmoothing.none,
    SceneSnap? snap,
    SceneCallbacks callbacks = const SceneCallbacks(),
    bool reduceMotion = false,
  }) {
    if (!identical(position, _position)) {
      _detachPosition();
      _position = position;
      position?.addListener(_onScroll);
      position?.isScrollingNotifier.addListener(_onScrollingChanged);
    }
    if (!identical(vsync, _vsync)) {
      _ticker?.dispose();
      _ticker = null;
      _vsync = vsync;
    }
    _snap = snap;
    _callbacks = callbacks;
    final smoothingChanged =
        smoothing != _smoothing || reduceMotion != _reduceMotion;
    _smoothing = smoothing;
    _reduceMotion = reduceMotion;
    if (smoothingChanged) {
      _spring = null;
      _ticker?.stop();
      _jumpTo(_raw);
    }
  }

  /// Disconnects from the scroll position and stops smoothing.
  void detach() {
    _detachPosition();
    _ticker?.dispose();
    _ticker = null;
    _vsync = null;
  }

  void _detachPosition() {
    _position?.removeListener(_onScroll);
    _position?.isScrollingNotifier.removeListener(_onScrollingChanged);
    _position = null;
  }

  /// Called by the render objects after measuring: records where in scroll
  /// space the scene lives and re-evaluates progress.
  void updateGeometry({
    required SceneRange range,
    required double fallbackPixels,
    required bool pinned,
  }) {
    _fallbackPixels = fallbackPixels;
    _pinned = pinned;
    if (range == _range) {
      _evaluate();
      return;
    }
    _range = range;
    _evaluate();
  }

  void _onScroll() => _evaluate();

  void _evaluate() {
    final range = _range;
    if (range == null) return;
    final raw = range.progressAt(pixels);
    if (_seeded && raw == _raw) return;
    _seeded = true;
    final events = _machine.update(raw);
    final changed = raw != _raw;
    _raw = raw;
    if (!changed) return;
    _callbacks.onProgress?.call(raw);
    for (final e in events) {
      _callbacks._dispatch(e);
    }
    _retarget(raw);
    _notify();
  }

  bool _seeded = false;

  bool get _inRenderPhase {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks;
  }

  void _notify() {
    if (_inRenderPhase) {
      if (_notifyScheduled) return;
      _notifyScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notifyScheduled = false;
        notifyListeners();
        _progress._flush();
      }, debugLabel: 'SceneController.notify');
      return;
    }
    notifyListeners();
    _progress._flush();
  }

  void _retarget(double target) {
    final ticker = _ensureTicker();
    final smoothing = _smoothing;
    if (_reduceMotion ||
        ticker == null ||
        (smoothing is! LerpSmoothing && smoothing is! SpringSmoothing)) {
      _jumpTo(target);
      return;
    }
    if ((_progress.value - target).abs() < 1e-6) {
      _jumpTo(target);
      return;
    }
    if (smoothing is SpringSmoothing) {
      final now =
          ticker.isActive ? (_lastTick ?? Duration.zero) : Duration.zero;
      _spring = SpringSimulation(
        smoothing.description,
        _progress.value,
        target,
        _velocity,
      );
      _springStart = now;
    }
    if (!ticker.isActive) {
      _lastTick = null;
      ticker.start();
    }
  }

  Ticker? _ensureTicker() {
    if (_ticker != null) return _ticker;
    final vsync = _vsync;
    if (vsync == null) return null;
    return _ticker = vsync.createTicker(_tick);
  }

  void _jumpTo(double value) {
    _velocity = 0;
    _spring = null;
    _progress._set(value, _machine.direction, deferred: _inRenderPhase);
  }

  void _tick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    final target = _raw;
    switch (_smoothing) {
      case LerpSmoothing(:final timeConstant):
        if (last == null) return;
        final dt = (elapsed - last).inMicroseconds / 1e6;
        final tau = math.max(timeConstant.inMicroseconds / 1e6, 1e-3);
        final alpha = 1 - math.exp(-dt / tau);
        final current = _progress.value;
        var next = current + (target - current) * alpha;
        _velocity = dt > 0 ? (next - current) / dt : 0;
        if ((target - next).abs() < 0.0005) {
          next = target;
          _ticker?.stop();
          _velocity = 0;
        }
        _progress._set(next, _machine.direction, deferred: false);
      case SpringSmoothing():
        final sim = _spring;
        if (sim == null) {
          _ticker?.stop();
          return;
        }
        if (last == null) {
          _springStart = elapsed;
          return;
        }
        final t = (elapsed - _springStart).inMicroseconds / 1e6;
        if (sim.isDone(t)) {
          _velocity = 0;
          _spring = null;
          _ticker?.stop();
          _progress._set(target, _machine.direction, deferred: false);
          return;
        }
        _velocity = sim.dx(t);
        _progress._set(
          sim.x(t).clamp(-0.25, 1.25),
          _machine.direction,
          deferred: false,
        );
      default:
        _ticker?.stop();
    }
  }

  void _onScrollingChanged() {
    final position = _position;
    final snap = _snap;
    final range = _range;
    if (position == null || snap == null || range == null) return;
    if (position.isScrollingNotifier.value) return;
    if (_snapping) {
      _snapping = false;
      return;
    }
    final raw = range.progressAt(position.pixels);
    if (raw <= 0 || raw >= 1 || snap.isSettled(raw)) return;
    final target = range
        .pixelsAt(snap.nearest(raw))
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    _snapping = true;
    position.animateTo(target, duration: snap.duration, curve: snap.curve);
  }

  /// Scroll offset at which this scene reaches [progress]; null before the
  /// first layout.
  double? pixelsForProgress(double progress) => _range?.pixelsAt(progress);

  @override
  void dispose() {
    detach();
    _progress.dispose();
    super.dispose();
  }

  @override
  String toString() =>
      '${describeIdentity(this)}(raw: ${_raw.toStringAsFixed(3)}, '
      'value: ${_progress.value.toStringAsFixed(3)}, range: $_range)';
}

class _SceneProgress extends Animation<double>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  double _value = 0;
  AnimationStatus _status = AnimationStatus.dismissed;
  bool _dirty = false;
  bool _statusDirty = false;

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  void _set(double value, SceneDirection direction, {required bool deferred}) {
    final status =
        value <= 0
            ? AnimationStatus.dismissed
            : value >= 1
            ? AnimationStatus.completed
            : direction == SceneDirection.forward
            ? AnimationStatus.forward
            : AnimationStatus.reverse;
    final valueChanged = value != _value;
    final statusChanged = status != _status;
    _value = value;
    _status = status;
    if (!valueChanged && !statusChanged) return;
    _dirty = _dirty || valueChanged;
    _statusDirty = _statusDirty || statusChanged;
    if (!deferred) _flush();
  }

  void _flush() {
    if (_statusDirty) {
      _statusDirty = false;
      notifyStatusListeners(_status);
    }
    if (_dirty) {
      _dirty = false;
      notifyListeners();
    }
  }

  void dispose() {
    clearListeners();
    clearStatusListeners();
  }

  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}
}
