## 0.1.0

Initial release.

- `SliverScrollScene` for `CustomScrollView` and `ScrollScene` drop-in for
  `ListView` / `Column` inside any scrollable.
- Pinning: a section stays fixed for `pinExtent` pixels of scroll while
  `progress` runs 0 → 1.
- Trigger positions for unpinned scenes (`ScenePosition.top(0.8)` etc.).
- `progress` exposed as `Animation<double>`; `SceneTimeline` keyframes and
  `Stagger` as `Animatable`s.
- Scrub smoothing (`lerp` / `spring`), honours `disableAnimations`.
- Snap points.
- Debug markers overlay.
- `onEnter`, `onLeave`, `onEnterBack`, `onLeaveBack`, `onProgress` callbacks.
