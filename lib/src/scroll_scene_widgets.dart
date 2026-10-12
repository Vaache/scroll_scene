import 'package:flutter/widgets.dart';

import 'render_scroll_scene_box.dart';
import 'render_sliver_scroll_scene.dart';
import 'scene_controller.dart';
import 'scene_markers.dart';
import 'scene_position.dart';
import 'scene_snap.dart';
import 'scrub_smoothing.dart';

/// Builds a scene's content with access to its [SceneController].
typedef SceneWidgetBuilder =
    Widget Function(BuildContext context, SceneController scene);

/// Default start trigger: the element's leading edge enters the viewport.
const ScenePosition kDefaultSceneStart = ScenePosition.top(1);

/// Default end trigger: the element's trailing edge leaves the viewport.
const ScenePosition kDefaultSceneEnd = ScenePosition.bottom(0);

/// Exposes the nearest enclosing scene's controller to descendants.
class ScrollSceneScope extends InheritedWidget {
  /// Creates a scope.
  const ScrollSceneScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The scene's controller.
  final SceneController controller;

  /// Nearest controller, or null when not inside a scene.
  static SceneController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ScrollSceneScope>()
          ?.controller;

  /// Nearest controller; throws when not inside a scene.
  static SceneController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No ScrollScene ancestor found.');
    return controller!;
  }

  @override
  bool updateShouldNotify(ScrollSceneScope oldWidget) =>
      !identical(oldWidget.controller, controller);
}

mixin _SceneConfig on StatefulWidget {
  double? get pinExtent;
  double? get pinnedExtent;
  ScenePosition get start;
  ScenePosition get end;
  ScrubSmoothing get smoothing;
  SceneSnap? get snap;
  SceneMarkers? get markers;
  SceneController? get controller;
  SceneCallbacks get callbacks;
  SceneWidgetBuilder? get builder;
  Widget? get child;
  bool get addRepaintBoundary;
}

abstract class _SceneState<T extends _SceneConfig> extends State<T>
    with SingleTickerProviderStateMixin {
  SceneController? _owned;
  late SceneController _controller =
      widget.controller ?? (_owned = SceneController());

  SceneController get controller => _controller;

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _controller.detach();
      _owned?.dispose();
      _owned = null;
      _controller = widget.controller ?? (_owned = SceneController());
      _attach();
    } else if (oldWidget.smoothing != widget.smoothing ||
        oldWidget.snap != widget.snap ||
        oldWidget.callbacks != widget.callbacks) {
      _attach();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attach();
  }

  void _attach() {
    _controller.attach(
      position: Scrollable.maybeOf(context)?.position,
      vsync: this,
      smoothing: widget.smoothing,
      snap: widget.snap,
      callbacks: widget.callbacks,
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
    );
  }

  @override
  void dispose() {
    _controller.detach();
    _owned?.dispose();
    super.dispose();
  }

  Widget buildContent(BuildContext context) {
    final content = widget.builder?.call(context, _controller) ?? widget.child!;
    return ScrollSceneScope(
      controller: _controller,
      child:
          widget.addRepaintBoundary ? RepaintBoundary(child: content) : content,
    );
  }
}

/// A scroll-driven scene for `CustomScrollView`.
///
/// With [pinExtent] the content stays fixed at the viewport's leading edge
/// for that many pixels of scroll while `scene.progress` runs 0 → 1. Without
/// it, progress runs between the [start] and [end] trigger positions.
class SliverScrollScene extends StatefulWidget with _SceneConfig {
  /// Creates a sliver scene. Provide exactly one of [builder] or [child].
  const SliverScrollScene({
    super.key,
    this.pinExtent,
    this.pinnedExtent,
    this.start = kDefaultSceneStart,
    this.end = kDefaultSceneEnd,
    this.smoothing = ScrubSmoothing.none,
    this.snap,
    this.markers,
    this.controller,
    this.callbacks = const SceneCallbacks(),
    this.addRepaintBoundary = true,
    this.builder,
    this.child,
  }) : assert(pinExtent == null || pinExtent >= 0),
       assert(
         (builder == null) != (child == null),
         'Provide builder or child.',
       );

  /// Pixels of scroll the content stays pinned for; null disables pinning.
  @override
  final double? pinExtent;

  /// Main-axis size of the pinned content; defaults to the viewport extent.
  @override
  final double? pinnedExtent;

  /// Trigger at which progress is 0 (unpinned scenes).
  @override
  final ScenePosition start;

  /// Trigger at which progress is 1 (unpinned scenes).
  @override
  final ScenePosition end;

  /// How the exposed progress follows the scroll.
  @override
  final ScrubSmoothing smoothing;

  /// Snap points, or null.
  @override
  final SceneSnap? snap;

  /// Debug markers; pass `SceneMarkers.defaults` to show them.
  @override
  final SceneMarkers? markers;

  /// External controller to share progress with other widgets.
  @override
  final SceneController? controller;

  /// Boundary and progress callbacks.
  @override
  final SceneCallbacks callbacks;

  /// Wraps content in a [RepaintBoundary] so scrubbing repaints only it.
  @override
  final bool addRepaintBoundary;

  /// Builds the content with access to the controller.
  @override
  final SceneWidgetBuilder? builder;

  /// Static content; use [ScrollSceneScope.of] to reach the controller.
  @override
  final Widget? child;

  @override
  State<SliverScrollScene> createState() => _SliverScrollSceneState();
}

class _SliverScrollSceneState extends _SceneState<SliverScrollScene> {
  @override
  Widget build(BuildContext context) => _SliverSceneRenderWidget(
    controller: controller,
    start: widget.start,
    end: widget.end,
    pinExtent: widget.pinExtent,
    pinnedExtent: widget.pinnedExtent,
    markers: widget.markers,
    child: buildContent(context),
  );
}

class _SliverSceneRenderWidget extends SingleChildRenderObjectWidget {
  const _SliverSceneRenderWidget({
    required this.controller,
    required this.start,
    required this.end,
    required this.pinExtent,
    required this.pinnedExtent,
    required this.markers,
    required super.child,
  });

  final SceneController controller;
  final ScenePosition start;
  final ScenePosition end;
  final double? pinExtent;
  final double? pinnedExtent;
  final SceneMarkers? markers;

  @override
  RenderSliverScrollScene createRenderObject(BuildContext context) =>
      RenderSliverScrollScene(
        controller: controller,
        start: start,
        end: end,
        pinExtent: pinExtent,
        pinnedExtent: pinnedExtent,
        markers: markers,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverScrollScene renderObject,
  ) {
    renderObject
      ..controller = controller
      ..start = start
      ..end = end
      ..pinExtent = pinExtent
      ..pinnedExtent = pinnedExtent
      ..markers = markers;
  }
}

/// A scroll-driven scene for box scrollables (`ListView`, `Column` inside a
/// `SingleChildScrollView`, ...). Same behaviour as [SliverScrollScene].
class ScrollScene extends StatefulWidget with _SceneConfig {
  /// Creates a box scene. Provide exactly one of [builder] or [child].
  const ScrollScene({
    super.key,
    this.pinExtent,
    this.pinnedExtent,
    this.start = kDefaultSceneStart,
    this.end = kDefaultSceneEnd,
    this.smoothing = ScrubSmoothing.none,
    this.snap,
    this.markers,
    this.controller,
    this.callbacks = const SceneCallbacks(),
    this.addRepaintBoundary = true,
    this.builder,
    this.child,
  }) : assert(pinExtent == null || pinExtent >= 0),
       assert(
         (builder == null) != (child == null),
         'Provide builder or child.',
       );

  /// Pixels of scroll the content stays pinned for; null disables pinning.
  @override
  final double? pinExtent;

  /// Main-axis size of the pinned content; defaults to the viewport extent.
  @override
  final double? pinnedExtent;

  /// Trigger at which progress is 0 (unpinned scenes).
  @override
  final ScenePosition start;

  /// Trigger at which progress is 1 (unpinned scenes).
  @override
  final ScenePosition end;

  /// How the exposed progress follows the scroll.
  @override
  final ScrubSmoothing smoothing;

  /// Snap points, or null.
  @override
  final SceneSnap? snap;

  /// Debug markers; pass `SceneMarkers.defaults` to show them.
  @override
  final SceneMarkers? markers;

  /// External controller to share progress with other widgets.
  @override
  final SceneController? controller;

  /// Boundary and progress callbacks.
  @override
  final SceneCallbacks callbacks;

  /// Wraps content in a [RepaintBoundary] so scrubbing repaints only it.
  @override
  final bool addRepaintBoundary;

  /// Builds the content with access to the controller.
  @override
  final SceneWidgetBuilder? builder;

  /// Static content; use [ScrollSceneScope.of] to reach the controller.
  @override
  final Widget? child;

  @override
  State<ScrollScene> createState() => _ScrollSceneState();
}

class _ScrollSceneState extends _SceneState<ScrollScene> {
  @override
  Widget build(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final axisDirection = scrollable?.axisDirection ?? AxisDirection.down;
    final size = MediaQuery.maybeSizeOf(context);
    final fallback =
        size == null
            ? null
            : switch (axisDirectionToAxis(axisDirection)) {
              Axis.vertical => size.height,
              Axis.horizontal => size.width,
            };
    return _BoxSceneRenderWidget(
      controller: controller,
      axisDirection: axisDirection,
      start: widget.start,
      end: widget.end,
      pinExtent: widget.pinExtent,
      pinnedExtent: widget.pinnedExtent,
      fallbackViewportExtent: fallback,
      markers: widget.markers,
      child: buildContent(context),
    );
  }
}

class _BoxSceneRenderWidget extends SingleChildRenderObjectWidget {
  const _BoxSceneRenderWidget({
    required this.controller,
    required this.axisDirection,
    required this.start,
    required this.end,
    required this.pinExtent,
    required this.pinnedExtent,
    required this.fallbackViewportExtent,
    required this.markers,
    required super.child,
  });

  final SceneController controller;
  final AxisDirection axisDirection;
  final ScenePosition start;
  final ScenePosition end;
  final double? pinExtent;
  final double? pinnedExtent;
  final double? fallbackViewportExtent;
  final SceneMarkers? markers;

  @override
  RenderScrollSceneBox createRenderObject(BuildContext context) =>
      RenderScrollSceneBox(
        controller: controller,
        axisDirection: axisDirection,
        start: start,
        end: end,
        pinExtent: pinExtent,
        pinnedExtent: pinnedExtent,
        fallbackViewportExtent: fallbackViewportExtent,
        markers: markers,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderScrollSceneBox renderObject,
  ) {
    renderObject
      ..controller = controller
      ..axisDirection = axisDirection
      ..start = start
      ..end = end
      ..pinExtent = pinExtent
      ..pinnedExtent = pinnedExtent
      ..fallbackViewportExtent = fallbackViewportExtent
      ..markers = markers;
  }
}
