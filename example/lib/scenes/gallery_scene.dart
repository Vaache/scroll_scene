import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import '../theme.dart';

const _cards = [
  ('Pin', 'Stick a section for N px of scroll.', kAccent),
  ('Scrub', 'progress is an Animation<double>.', kAccent2),
  ('Keyframes', 'SceneTimeline + Stagger, declarative.', kAccent3),
  ('Snap', 'Settle to points when scrolling stops.', Color(0xFFFFB347)),
  ('Markers', 'GSAP-style debug overlay.', Color(0xFF5CC8FF)),
];

class GalleryScene extends StatelessWidget {
  const GalleryScene({super.key, this.markers});

  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => SliverScrollScene(
    pinExtent: 1800,
    smoothing: const ScrubSmoothing.lerp(Duration(milliseconds: 120)),
    markers: markers?.copyWith(label: 'gallery'),
    builder: (context, scene) => _GalleryBody(scene: scene),
  );
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody({required this.scene});

  final SceneController scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = 260.0;
        const gap = 20.0;
        final rowWidth = _cards.length * (cardWidth + gap) - gap;
        final travel = (rowWidth - constraints.maxWidth + 56).clamp(
          0.0,
          double.infinity,
        );
        final x = scene.progress.drive(
          Tween<double>(
            begin: 0,
            end: -travel,
          ).chain(CurveTween(curve: Curves.linear)),
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('horizontal from vertical'),
                  const SizedBox(height: 12),
                  Text(
                    'Scroll down,\nthe gallery slides across.',
                    style: theme.textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 340,
              child: AnimatedBuilder(
                animation: x,
                builder:
                    (context, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 28 + x.value,
                          top: 0,
                          child: Row(
                            children: [
                              for (var i = 0; i < _cards.length; i++) ...[
                                _Card(
                                  index: i,
                                  width: cardWidth,
                                  progress: scene.progress.value,
                                  travel: travel,
                                  x: x.value,
                                ),
                                if (i != _cards.length - 1)
                                  const SizedBox(width: gap),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: scene.progress,
                builder:
                    (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: scene.progress.value,
                        minHeight: 3,
                        backgroundColor: kCard,
                        color: kInk,
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.index,
    required this.width,
    required this.progress,
    required this.travel,
    required this.x,
  });

  final int index;
  final double width;
  final double progress;
  final double travel;
  final double x;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body, color) = _cards[index];
    final center = 28 + x + index * (width + 20) + width / 2;
    final screenCenter = MediaQuery.sizeOf(context).width / 2;
    final focus = (1 - ((center - screenCenter).abs() / 300)).clamp(0.0, 1.0);
    return Transform.scale(
      scale: 0.92 + 0.08 * focus,
      child: Container(
        width: width,
        height: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Color.lerp(const Color(0xFF26262F), color, focus)!,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '0${index + 1}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const Spacer(),
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
