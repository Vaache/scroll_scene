import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

void main() => runApp(const ScrollSceneExampleApp());

class ScrollSceneExampleApp extends StatefulWidget {
  const ScrollSceneExampleApp({super.key});

  @override
  State<ScrollSceneExampleApp> createState() => _ScrollSceneExampleAppState();
}

class _ScrollSceneExampleAppState extends State<ScrollSceneExampleApp> {
  bool _markers = false;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'scroll_scene',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: Scaffold(
      body: LandingPage(markers: _markers ? SceneMarkers.defaults : null),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Toggle debug markers',
        backgroundColor: _markers ? kAccent : kCard,
        foregroundColor: kInk,
        onPressed: () => setState(() => _markers = !_markers),
        child: const Icon(Icons.straighten),
      ),
    ),
  );
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, this.controller, this.markers});

  final ScrollController? controller;
  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: controller,
    slivers: [
      HeroScene(markers: markers),
      PhoneScene(markers: markers),
      GalleryScene(markers: markers),
      RevealScene(markers: markers),
      SnapScene(markers: markers),
      const SliverToBoxAdapter(child: _Footer()),
    ],
  );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 60, 28, 80),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('that is scroll_scene'),
        const SizedBox(height: 12),
        Text(
          'pub.dev/packages/scroll_scene',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: kInk),
        ),
      ],
    ),
  );
}

const kBg = Color(0xFF0B0B0F);
const kInk = Color(0xFFF4F4F6);
const kMuted = Color(0xFF8A8A96);
const kAccent = Color(0xFF7C5CFF);
const kAccent2 = Color(0xFF34D1BF);
const kAccent3 = Color(0xFFFF6B9D);
const kCard = Color(0xFF16161D);

ThemeData buildTheme({String? fontFamily}) => ThemeData(
  brightness: Brightness.dark,
  fontFamily: fontFamily,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    primary: kAccent,
    secondary: kAccent2,
    surface: kCard,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 44,
      height: 1.05,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      color: kInk,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: kInk,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: kMuted),
    labelSmall: TextStyle(
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      color: kAccent2,
    ),
  ),
  useMaterial3: true,
);

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall);
}

const _heroWords = [
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
                  for (var i = 0; i < _heroWords.length; i++)
                    _HeroWord(
                      _heroWords[i],
                      t: scene.progress.drive(
                        Stagger(
                          index: i,
                          count: _heroWords.length,
                          duration: 0.3,
                        ),
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

class _HeroWord extends StatelessWidget {
  const _HeroWord(this.text, {required this.t, required this.style});

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

class PhoneScene extends StatelessWidget {
  const PhoneScene({super.key, this.markers});

  final SceneMarkers? markers;

  @override
  Widget build(BuildContext context) => SliverScrollScene(
    pinExtent: 1600,
    smoothing: const ScrubSmoothing.spring(stiffness: 220, damping: 28),
    markers: markers?.copyWith(label: 'phone'),
    builder: (context, scene) => _PhoneBody(scene: scene),
  );
}

class _PhoneBody extends StatelessWidget {
  const _PhoneBody({required this.scene});

  final SceneController scene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = scene.progress;
    final body = p.drive(
      SceneTimeline.offset([
        const Keyframe(0, Offset(0, 420)),
        const Keyframe(0.35, Offset.zero, curve: Curves.easeOutCubic),
      ]),
    );
    final screen = p.drive(
      SceneTimeline.offset([
        const Keyframe(0.2, Offset(-320, -120)),
        const Keyframe(0.55, Offset.zero, curve: Curves.easeOutBack),
      ]),
    );
    final camera = p.drive(
      SceneTimeline.offset([
        const Keyframe(0.35, Offset(260, -260)),
        const Keyframe(0.7, Offset.zero, curve: Curves.easeOutBack),
      ]),
    );
    final buttons = p.drive(
      SceneTimeline.offset([
        const Keyframe(0.5, Offset(240, 160)),
        const Keyframe(0.8, Offset.zero, curve: Curves.easeOutCubic),
      ]),
    );
    final tilt = p.drive(
      SceneTimeline.number([
        const Keyframe(0, -0.35),
        const Keyframe(0.8, 0, curve: Curves.easeOut),
        const Keyframe(1, 0.12, curve: Curves.easeInOut),
      ]),
    );
    final glow = p.drive(
      SceneTimeline.number([
        const Keyframe(0.75, 0),
        const Keyframe(1, 1, curve: Curves.easeIn),
      ]),
    );
    final caption = p.drive(
      SceneTimeline.number([
        const Keyframe(0, 0),
        const Keyframe(0.15, 1),
        const Keyframe(0.75, 1),
        const Keyframe(0.9, 0),
      ]),
    );
    final caption2 = p.drive(
      SceneTimeline.number([const Keyframe(0.85, 0), const Keyframe(1, 1)]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('pin + keyframes'),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Stack(
              children: [
                FadeTransition(
                  opacity: caption,
                  child: Text(
                    'Parts fly in\nas you scroll.',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                FadeTransition(
                  opacity: caption2,
                  child: Text(
                    'Assembled.\nPinned for 1600 px.',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: p,
                builder:
                    (context, _) => Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(tilt.value)
                            ..rotateZ(tilt.value * 0.25),
                      child: SizedBox(
                        width: 200,
                        height: 400,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: glow.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(44),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kAccent.withValues(alpha: 0.6),
                                        blurRadius: 60,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _part(body.value, _PhoneBodyPart()),
                            _part(screen.value, _ScreenPart(progress: p.value)),
                            _part(camera.value, const _CameraPart()),
                            _part(buttons.value, const _ButtonsPart()),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _part(Offset offset, Widget child) => Positioned.fill(
    child: Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: (1 - offset.distance / 500).clamp(0.0, 1.0),
        child: child,
      ),
    ),
  );
}

class _PhoneBodyPart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(44),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A2A36), Color(0xFF14141B)],
      ),
      border: Border.all(color: const Color(0xFF3B3B4A), width: 2),
    ),
  );
}

class _ScreenPart extends StatelessWidget {
  const _ScreenPart({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: CustomPaint(painter: _ScreenPainter(progress)),
    ),
  );
}

class _ScreenPainter extends CustomPainter {
  _ScreenPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1830), Color(0xFF0D0D12)],
        ).createShader(rect),
    );
    final on = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
    if (on == 0) return;
    for (var i = 0; i < 5; i++) {
      final y = 90.0 + i * 46;
      final w = size.width * (0.45 + 0.1 * math.sin(i * 1.7)) * on;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(22, y, w, 14),
          const Radius.circular(7),
        ),
        Paint()
          ..color = (i == 0 ? kAccent : kMuted).withValues(alpha: 0.5 * on),
      );
    }
    canvas.drawCircle(
      Offset(size.width / 2, 48),
      14 * on,
      Paint()..color = kAccent2.withValues(alpha: on),
    );
  }

  @override
  bool shouldRepaint(_ScreenPainter old) => old.t != t;
}

class _CameraPart extends StatelessWidget {
  const _CameraPart();

  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, -0.92),
    child: Container(
      width: 56,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF07070A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: const Alignment(0.6, 0),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2E3A6B),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  );
}

class _ButtonsPart extends StatelessWidget {
  const _ButtonsPart();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(right: -5, top: 110, child: _pill(60)),
      Positioned(left: -5, top: 90, child: _pill(32)),
      Positioned(left: -5, top: 130, child: _pill(32)),
    ],
  );

  Widget _pill(double h) => Container(
    width: 5,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFF4A4A5C),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

const _galleryCards = [
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
        final rowWidth = _galleryCards.length * (cardWidth + gap) - gap;
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
                              for (
                                var i = 0;
                                i < _galleryCards.length;
                                i++
                              ) ...[
                                _GalleryCard(
                                  index: i,
                                  width: cardWidth,
                                  progress: scene.progress.value,
                                  travel: travel,
                                  x: x.value,
                                ),
                                if (i != _galleryCards.length - 1)
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

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
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
    final (title, body, color) = _galleryCards[index];
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

const _revealRows = [
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
              for (var i = 0; i < _revealRows.length; i++)
                _RevealRow(
                  index: i,
                  t: scene.progress.drive(
                    Stagger(
                      index: i,
                      count: _revealRows.length,
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

class _RevealRow extends StatelessWidget {
  const _RevealRow({required this.index, required this.t});

  final int index;
  final Animation<double> t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, body) = _revealRows[index];
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

const _snapSlides = [
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
        final p = scene.progress.value * (_snapSlides.length - 1);
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
                    for (var i = 0; i < _snapSlides.length; i++)
                      _SnapSlide(
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
                  for (var i = 0; i < _snapSlides.length; i++)
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

class _SnapSlide extends StatelessWidget {
  const _SnapSlide({
    required this.index,
    required this.weight,
    required this.style,
  });

  final int index;
  final double weight;
  final ThemeData style;

  @override
  Widget build(BuildContext context) {
    final (title, body, color) = _snapSlides[index];
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
