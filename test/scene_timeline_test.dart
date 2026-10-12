import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_scene/scroll_scene.dart';

void main() {
  group('SceneTimeline', () {
    test('holds first and last values outside keyframes', () {
      final tl = SceneTimeline.number([
        const Keyframe(0.2, 10),
        const Keyframe(0.8, 20),
      ]);
      expect(tl.transform(0), 10);
      expect(tl.transform(0.2), 10);
      expect(tl.transform(0.5), 15);
      expect(tl.transform(0.8), 20);
      expect(tl.transform(1), 20);
    });

    test('sorts keyframes and applies segment curve', () {
      final tl = SceneTimeline.number([
        const Keyframe(1, 1, curve: Curves.easeIn),
        const Keyframe(0, 0),
      ]);
      expect(tl.keyframes.first.offset, 0);
      expect(tl.transform(0.5), Curves.easeIn.transform(0.5));
    });

    test('typed factories interpolate', () {
      final o = SceneTimeline.offset([
        const Keyframe(0, Offset.zero),
        const Keyframe(1, Offset(10, 20)),
      ]);
      expect(o.transform(0.5), const Offset(5, 10));
      final c = SceneTimeline.color([
        const Keyframe(0, Color(0xFF000000)),
        const Keyframe(1, Color(0xFFFFFFFF)),
      ]);
      expect(c.transform(0.5).r, closeTo(0.5, 0.01));
    });

    test('drives an Animation', () {
      final controller = AnimationController(vsync: const TestVSync());
      final anim = controller.drive(
        SceneTimeline.number([const Keyframe(0, 0), const Keyframe(1, 100)]),
      );
      controller.value = 0.25;
      expect(anim.value, 25);
      controller.dispose();
    });
  });

  group('Stagger', () {
    test('default spreads sequential windows', () {
      const s0 = Stagger(index: 0, count: 4);
      const s3 = Stagger(index: 3, count: 4);
      expect(s0.interval.begin, 0);
      expect(s0.interval.end, 0.25);
      expect(s3.interval.begin, closeTo(0.75, 1e-9));
      expect(s3.interval.end, 1);
      expect(s0.transform(0.125), 0.5);
      expect(s3.transform(0.5), 0);
    });

    test('each overlaps windows and ends at 1', () {
      const last = Stagger(index: 2, count: 3, each: 0.1);
      expect(last.interval.begin, closeTo(0.2, 1e-9));
      expect(last.interval.end, 1);
      const first = Stagger(index: 0, count: 3, each: 0.1);
      expect(first.interval.end, closeTo(0.8, 1e-9));
    });

    test('from end reverses order', () {
      const s = Stagger(index: 0, count: 3, from: StaggerFrom.end);
      expect(s.interval.begin, closeTo(2 / 3, 1e-9));
    });

    test('from center starts in the middle', () {
      const mid = Stagger(index: 2, count: 5, from: StaggerFrom.center);
      const edge = Stagger(index: 0, count: 5, from: StaggerFrom.center);
      expect(mid.interval.begin, 0);
      expect(edge.interval.end, 1);
    });
  });
}
