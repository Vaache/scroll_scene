# scroll_scene

GSAP ScrollTrigger for Flutter. Pin a section for N pixels of scroll, scrub a
timeline by scroll progress, drive keyframes and staggers, snap to points, and
debug it all with GSAP‑style markers. Pure Flutter, no dependencies.

| Pin + stagger | Pin + keyframes | Horizontal from vertical |
| --- | --- | --- |
| ![hero](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/hero.gif) | ![phone](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/phone.gif) | ![gallery](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/gallery.gif) |

| Reveal (unpinned triggers) | Snap points | Debug markers |
| --- | --- | --- |
| ![reveal](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/reveal.gif) | ![snap](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/snap.gif) | ![markers](https://raw.githubusercontent.com/Vaache/scroll_scene/main/doc/media/markers.gif) |

## Why

pub.dev has reveal‑on‑scroll widgets, image‑sequence scrubbers and keyframe
libraries, but nothing that combines **pin + scrub + keyframes/stagger + snap +
markers** in one scroll‑aware primitive. `scroll_scene` is that primitive.

## Install

```yaml
dependencies:
  scroll_scene: ^0.1.0
```

## Quick start

```dart
CustomScrollView(
  slivers: [
    SliverScrollScene(
      pinExtent: 1200,                       // stays pinned for 1200 px of scroll
      smoothing: const ScrubSmoothing.lerp(), // optional, buttery scrub
      builder: (context, scene) => AnimatedBuilder(
        animation: scene.progress,            // Animation<double>, 0 → 1
        builder: (_, _) => Opacity(
          opacity: scene.progress.value,
          child: const FlutterLogo(size: 200),
        ),
      ),
    ),
  ],
)
```

Inside a `ListView` or `Column` use `ScrollScene` with the same parameters.

## Concepts

### Pin

`pinExtent` makes the content stick to the viewport's leading edge while the
user scrolls that many pixels. The scene occupies `content + pinExtent` of
scroll space, so nothing jumps when it unpins. `progress` is the distance
scrolled inside the pin divided by `pinExtent`.

By default the pinned content is sized to the viewport; set `pinnedExtent` to
pin something shorter.

### Triggers (unpinned scenes)

Without `pinExtent`, progress runs between two `ScenePosition`s:

```dart
SliverScrollScene(
  start: const ScenePosition.top(0.8),   // GSAP "top 80%"
  end: const ScenePosition.bottom(0.2),  // GSAP "bottom 20%"
  ...
)
```

`ScenePosition(element: 0..1, viewport: 0..1)` means "the point at `element`
of the widget reaches the point at `viewport` of the viewport". Defaults are
`top(1)` → `bottom(0)`: the full pass through the viewport.

### Scrub

`scene.progress` is an `Animation<double>`, so it works with everything that
takes one: `AnimatedBuilder`, `FadeTransition`, `Tween.animate`, `drive`.

```dart
smoothing: ScrubSmoothing.none                              // exact
smoothing: ScrubSmoothing.lerp(Duration(milliseconds: 120)) // exponential ease
smoothing: ScrubSmoothing.spring(stiffness: 180, damping: 24)
```

When `MediaQuery.disableAnimations` is true, smoothing is skipped and progress
jumps. `scene.rawProgress` is always the unsmoothed value.

### Keyframes and stagger

`SceneTimeline` is an `Animatable`, so plug it straight into `drive`:

```dart
final x = scene.progress.drive(SceneTimeline.offset([
  Keyframe(0.0, Offset(0, 300)),
  Keyframe(0.4, Offset.zero, curve: Curves.easeOutCubic),
  Keyframe(1.0, Offset(0, -40)),
]));

final color = scene.progress.drive(SceneTimeline.color([
  Keyframe(0, Colors.purple),
  Keyframe(1, Colors.teal),
]));
```

Factories: `number`, `offset`, `color`, `size`, `rect`, `alignment`,
`edgeInsets`, or `SceneTimeline<T>(keyframes, lerp: ...)` for anything else.

`Stagger` offsets each item's window so lists animate one after another:

```dart
for (var i = 0; i < items.length; i++)
  FadeTransition(
    opacity: scene.progress.drive(
      Stagger(index: i, count: items.length, each: 0.1),
    ),
    child: items[i],
  )
```

### Snap

```dart
snap: const SceneSnap(points: [0, 0.5, 1]),
```

When the user stops scrolling inside the scene, the scroll position animates to
the nearest point.

### Callbacks

```dart
callbacks: SceneCallbacks(
  onEnter: () {},       // progress left 0 scrolling forward
  onLeave: () {},       // progress reached 1
  onEnterBack: () {},   // progress left 1 scrolling back
  onLeaveBack: () {},   // progress reached 0
  onProgress: (p) {},   // raw progress changed
),
```

### Markers

```dart
markers: const SceneMarkers(label: 'hero'),
```

Draws `start` / `end` lines on the element, `scroller-start` / `scroller-end`
lines on the viewport, the pin band and a live progress badge.

### Sharing progress

Pass your own `SceneController` to read the progress from outside the scene,
for example a fixed header or a background:

```dart
final scene = SceneController();
...
SliverScrollScene(controller: scene, pinExtent: 800, child: ...),
...
AnimatedBuilder(animation: scene.progress, builder: ...)
```

Descendants can also call `ScrollSceneScope.of(context)`.

## Performance

- Progress is computed from the `ScrollPosition` before the frame builds, so
  dependents rebuild in the same frame with no lag and no "build scheduled
  during frame" assertions.
- Pinning is pure sliver layout arithmetic; the box variant translates its
  child at paint time.
- Only widgets listening to `progress` rebuild. Content is wrapped in a
  `RepaintBoundary` by default (`addRepaintBoundary: false` to opt out).
- Smoothing runs a single `Ticker` per scene that stops when settled.

## Limitations

- The box variant (`ScrollScene`) needs an enclosing `RenderAbstractViewport`
  (`ListView`, `SingleChildScrollView`, ...). It cannot know the viewport size
  before its first layout, so pinned content falls back to `MediaQuery` size
  for one frame when no viewport is measurable.
- Scenes below the viewport and outside the cache area resolve their position
  approximately until they are laid out; progress there is 0 anyway.
- Viewports with a non‑zero `anchor` or `center` are not supported for
  trigger math.
- Snapping waits for the ballistic scroll to finish, then animates; it does not
  predict the fling destination like GSAP's `snap.inertia`.

## Example

`example/` is a scroll‑telling landing page with every feature. The README
media is rendered headlessly from it with `tool/render_media.sh`.

## License

MIT © 2026 Vachagan Hovhannisyan
