import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import '../theme.dart';

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
