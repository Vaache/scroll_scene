import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_scene/scroll_scene.dart';

void main() {
  group('ScenePosition', () {
    test('top(0.8) measures element top against 80% of viewport', () {
      const p = ScenePosition.top(0.8);
      expect(
        p.distance(leadingEdge: 800, elementExtent: 200, viewportExtent: 1000),
        0,
      );
      expect(
        p.distance(leadingEdge: 700, elementExtent: 200, viewportExtent: 1000),
        100,
      );
    });

    test('bottom(0) measures element bottom against viewport top', () {
      const p = ScenePosition.bottom(0);
      expect(
        p.distance(leadingEdge: -200, elementExtent: 200, viewportExtent: 1000),
        0,
      );
    });
  });

  group('SceneRange', () {
    test('pinned range starts where leading edge hits viewport top', () {
      final r = SceneRange.pinned(
        pixels: 1000,
        leadingEdge: 300,
        pinExtent: 800,
      );
      expect(r.start, 1300);
      expect(r.end, 2100);
      expect(r.progressAt(1300), 0);
      expect(r.progressAt(1700), 0.5);
      expect(r.progressAt(2100), 1);
      expect(r.progressAt(5000), 1);
      expect(r.progressAt(0), 0);
      expect(r.pixelsAt(0.25), 1500);
    });

    test('pinned range mid-pin resolves same start', () {
      final r = SceneRange.pinned(pixels: 1700, leadingEdge: 0, pinExtent: 800);
      expect(r.start, 1700);
      final r2 = SceneRange.pinned(
        pixels: 1900,
        leadingEdge: 0,
        pinExtent: 800,
      );
      expect(r2.start, 1900);
    });

    test('triggered range: enter bottom, leave top', () {
      final r = SceneRange.triggered(
        pixels: 0,
        leadingEdge: 1000,
        elementExtent: 400,
        viewportExtent: 1000,
        start: const ScenePosition.top(1),
        end: const ScenePosition.bottom(0),
      );
      expect(r.start, 0);
      expect(r.extent, 1400);
      expect(r.progressAt(700), closeTo(0.5, 1e-9));
    });

    test('triggered range: top 80% to top 20%', () {
      final r = SceneRange.triggered(
        pixels: 500,
        leadingEdge: 900,
        elementExtent: 300,
        viewportExtent: 1000,
        start: const ScenePosition.top(0.8),
        end: const ScenePosition.top(0.2),
      );
      expect(r.start, 600);
      expect(r.extent, 600);
      expect(r.progressAt(900), 0.5);
    });

    test('zero extent range is a step', () {
      const r = SceneRange(start: 10, extent: 0);
      expect(r.progressAt(9), 0);
      expect(r.progressAt(10), 1);
    });
  });

  group('SceneSnap', () {
    const snap = SceneSnap(points: [0, 0.5, 1]);
    test('nearest', () {
      expect(snap.nearest(0.2), 0);
      expect(snap.nearest(0.3), 0.5);
      expect(snap.nearest(0.8), 1);
    });
    test('settled within tolerance', () {
      expect(snap.isSettled(0.501), isTrue);
      expect(snap.isSettled(0.52), isFalse);
    });
  });
}
