import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import '../theme.dart';

const _rows = [
  ('Works as a sliver', 'SliverScrollScene inside CustomScrollView.'),
  ('Works in ListView', 'ScrollScene wraps any box child.'),
  ('No setState per tick', 'Progress is a Listenable; children opt in.'),
  ('Reduced motion aware', 'disableAnimations means no smoothing, no springs.'),
];

class RevealScene extends StatelessWidget {
  const RevealScene({super.key, this.markers});

  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => SliverScrollScene(
    start: const ScenePosition.top(0.85),
    end: const ScenePosition.bottom(0.75),
    markers: markers?.copyWith(label: 'reveal'),
    builder:
        (context, scene) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 80, 28, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('reveal, unpinned'),
              const SizedBox(height: 12),
              Text(
                'Triggered by position,\nstaggered by index.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _rows.length; i++)
                _Row(
                  index: i,
                  t: scene.progress.drive(
                    Stagger(
                      index: i,
                      count: _rows.length,
                      each: 0.18,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
            ],
          ),
        ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.index, required this.t});

  final int index;
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body) = _rows[index];
    return AnimatedBuilder(
      animation: t,
      builder:
          (context, child) => Opacity(
            opacity: t.value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - t.value)),
              child: child,
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: [
                  kAccent,
                  kAccent2,
                  kAccent3,
                  Colors.orange,
                ][index].withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: [kAccent, kAccent2, kAccent3, Colors.orange][index],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: kInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(body, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
