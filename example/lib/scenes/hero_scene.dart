import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import '../theme.dart';

const _words = [
  'Pin.',
  'Scrub.',
  'Snap.',
  'Scroll-driven',
  'motion,',
  'the',
  'Flutter',
  'way.',
];

class HeroScene extends StatelessWidget {
  const HeroScene({super.key, this.markers});

  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => SliverScrollScene(
    pinExtent: 1400,
    smoothing: const ScrubSmoothing.lerp(Duration(milliseconds: 90)),
    markers: markers?.copyWith(label: 'hero'),
    builder: (context, scene) => _HeroBody(scene: scene),
  );
}

class _HeroBody extends StatelessWidget {
  const _HeroBody({required this.scene});

  final SceneController scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glow = scene.progress.drive(
      SceneTimeline.offset([
        const Keyframe(0, Offset(-0.6, -0.8)),
        const Keyframe(0.5, Offset(0.7, 0.2), curve: Curves.easeInOut),
        const Keyframe(1, Offset(-0.2, 0.9), curve: Curves.easeInOut),
      ]),
    );
    final glowColor = scene.progress.drive(
      SceneTimeline.color([
        const Keyframe(0, kAccent),
        const Keyframe(0.5, kAccent2),
        const Keyframe(1, kAccent3),
      ]),
    );
    final hint = scene.progress.drive(
      SceneTimeline.number([const Keyframe(0, 1), const Keyframe(0.15, 0)]),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: scene.progress,
          builder:
              (context, _) => Align(
                alignment: Alignment(glow.value.dx, glow.value.dy),
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor.value.withValues(alpha: 0.55),
                        glowColor.value.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('scroll_scene'),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 2,
                children: [
                  for (var i = 0; i < _words.length; i++)
                    _Word(
                      _words[i],
                      t: scene.progress.drive(
                        Stagger(index: i, count: _words.length, duration: 0.3),
                      ),
                      style: theme.textTheme.displayLarge!,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: hint,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: kMuted, size: 16),
                    const SizedBox(width: 8),
                    Text('Scroll to scrub', style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Word extends StatelessWidget {
  const _Word(this.text, {required this.t, required this.style});

  final String text;
  final Animation<double> t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: t,
    builder: (context, _) {
      final v = Curves.easeOutCubic.transform(t.value);
      return Transform.translate(
        offset: Offset(0, 18 * (1 - v)),
        child: Text(
          text,
          style: style.copyWith(
            color: Color.lerp(kInk.withValues(alpha: 0.18), kInk, v),
          ),
        ),
      );
    },
  );
}
