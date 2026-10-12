import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import '../theme.dart';

const _slides = [
  ('Snap points', '[0, 0.5, 1]\nRelease anywhere, land on a slide.', kAccent),
  (
    'Half way',
    'Progress 0.5. The scroll position\nanimated here on its own.',
    kAccent2,
  ),
  ('Done', 'Progress 1. Keep scrolling\nto unpin.', kAccent3),
];

class SnapScene extends StatelessWidget {
  const SnapScene({super.key, this.markers});

  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => SliverScrollScene(
    pinExtent: 1200,
    snap: const SceneSnap(points: [0, 0.5, 1]),
    markers: markers?.copyWith(label: 'snap'),
    builder: (context, scene) => _SnapBody(scene: scene),
  );
}

class _SnapBody extends StatelessWidget {
  const _SnapBody({required this.scene});

  final SceneController scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: scene.progress,
      builder: (context, _) {
        final p = scene.progress.value * (_slides.length - 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('snap'),
              const SizedBox(height: 24),
              SizedBox(
                height: 360,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      _Slide(
                        index: i,
                        weight: (1 - (p - i).abs()).clamp(0.0, 1.0),
                        style: theme,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      width: (p - i).abs() < 0.5 ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (p - i).abs() < 0.5 ? kInk : kMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.index,
    required this.weight,
    required this.style,
  });

  final int index;
  final double weight;
  final ThemeData style;

  @override
  Widget build(BuildContext context) {
    final (title, body, color) = _slides[index];
    return IgnorePointer(
      child: Opacity(
        opacity: weight,
        child: Transform.scale(
          scale: 0.9 + 0.1 * weight,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0${index + 1}',
                  style: style.textTheme.labelSmall!.copyWith(color: kInk),
                ),
                const Spacer(),
                Text(
                  title,
                  style: style.textTheme.displayLarge!.copyWith(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: style.textTheme.bodyLarge!.copyWith(
                    color: kInk.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
