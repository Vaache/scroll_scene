import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_scene/scroll_scene.dart';

const viewport = Size(400, 800);

Widget app(Widget child, {bool reduceMotion = false}) => MediaQuery(
  data: MediaQueryData(size: viewport, disableAnimations: reduceMotion),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

Widget slivers({
  required ScrollController controller,
  required Widget scene,
  double before = 1000,
  double after = 3000,
}) => CustomScrollView(
  controller: controller,
  slivers: [
    SliverToBoxAdapter(child: SizedBox(height: before)),
    scene,
    SliverToBoxAdapter(child: SizedBox(height: after)),
  ],
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> setSize(WidgetTester tester) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('SliverScrollScene pin', () {
    testWidgets('occupies child + pinExtent of scroll and sticks to the top', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      const key = Key('pinned');
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1200,
              controller: scene,
              child: const ColoredBox(color: Colors.red, key: key),
            ),
          ),
        ),
      );
      expect(scroll.position.maxScrollExtent, 1000 + 800 + 1200 + 3000 - 800);

      scroll.jumpTo(1000);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, 0);
      expect(tester.getSize(find.byKey(key)).height, 800);
      expect(scene.rawProgress, 0);

      scroll.jumpTo(1600);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, 0);
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      expect(scene.progress.value, closeTo(0.5, 1e-9));

      scroll.jumpTo(2200);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, 0);
      expect(scene.rawProgress, 1);

      scroll.jumpTo(2500);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, -300);
      expect(scene.rawProgress, 1);

      scroll.jumpTo(700);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, 300);
      expect(scene.rawProgress, 0);
    });

    testWidgets('pinnedExtent overrides the viewport height', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      const key = Key('pinned');
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: const SliverScrollScene(
              pinExtent: 500,
              pinnedExtent: 300,
              child: ColoredBox(color: Colors.red, key: key),
            ),
          ),
        ),
      );
      scroll.jumpTo(1000);
      await tester.pump();
      expect(tester.getSize(find.byKey(key)).height, 300);
      expect(scroll.position.maxScrollExtent, 1000 + 300 + 500 + 3000 - 800);
    });

    testWidgets('initial offset inside the pin resolves after first frame', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController(initialScrollOffset: 1600);
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1200,
              controller: scene,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      await tester.pump();
      expect(scene.progress.value, closeTo(0.5, 1e-9));
    });
  });

  group('SliverScrollScene triggers', () {
    testWidgets('default triggers span full visibility', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              controller: scene,
              child: const SizedBox(height: 400),
            ),
          ),
        ),
      );
      scroll.jumpTo(100);
      await tester.pump();
      expect(scene.rawProgress, 0);
      scroll.jumpTo(200);
      await tester.pump();
      expect(scene.rawProgress, 0);
      scroll.jumpTo(800);
      await tester.pump();
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      scroll.jumpTo(1400);
      await tester.pump();
      expect(scene.rawProgress, 1);
    });

    testWidgets('custom triggers top 80% → top 20%', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              controller: scene,
              start: const ScenePosition.top(0.8),
              end: const ScenePosition.top(0.2),
              child: const SizedBox(height: 400),
            ),
          ),
        ),
      );
      scroll.jumpTo(360);
      await tester.pump();
      expect(scene.rawProgress, 0);
      scroll.jumpTo(600);
      await tester.pump();
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      scroll.jumpTo(840);
      await tester.pump();
      expect(scene.rawProgress, 1);
    });
  });

  group('callbacks', () {
    testWidgets('enter/leave/enterBack/leaveBack fire in order', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final log = <String>[];
      final progress = <double>[];
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1000,
              callbacks: SceneCallbacks(
                onEnter: () => log.add('enter'),
                onLeave: () => log.add('leave'),
                onEnterBack: () => log.add('enterBack'),
                onLeaveBack: () => log.add('leaveBack'),
                onProgress: progress.add,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(1500);
      await tester.pump();
      scroll.jumpTo(2000);
      await tester.pump();
      scroll.jumpTo(1900);
      await tester.pump();
      scroll.jumpTo(500);
      await tester.pump();
      expect(log, ['enter', 'leave', 'enterBack', 'leaveBack']);
      expect(progress, [0.5, 1, 0.9, 0]);
    });
  });

  group('smoothing', () {
    testWidgets('lerp approaches the target over time', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1000,
              controller: scene,
              smoothing: const ScrubSmoothing.lerp(Duration(milliseconds: 100)),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(1500);
      await tester.pump();
      expect(scene.rawProgress, 0.5);
      expect(scene.progress.value, 0);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = scene.progress.value;
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.5));
      await tester.pump(const Duration(seconds: 2));
      expect(scene.progress.value, 0.5);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('spring settles on the target', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1000,
              controller: scene,
              smoothing: const ScrubSmoothing.spring(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(1800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 60));
      expect(scene.progress.value, greaterThan(0));
      expect(scene.progress.value, lessThan(0.8));
      await tester.pump(const Duration(seconds: 3));
      expect(scene.progress.value, 0.8);
    });

    testWidgets('reduced motion disables smoothing', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          reduceMotion: true,
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1000,
              controller: scene,
              smoothing: const ScrubSmoothing.lerp(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(1500);
      await tester.pump();
      expect(scene.progress.value, 0.5);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('snap', () {
    testWidgets('settles to the nearest point after a drag', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 1000,
              controller: scene,
              snap: const SceneSnap(points: [0, 0.5, 1]),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(1000);
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -380));
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(1500, 0.5));
      expect(scene.rawProgress, closeTo(0.5, 1e-3));
    });

    testWidgets('does nothing when already on a point', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: const SliverScrollScene(
              pinExtent: 1000,
              snap: SceneSnap(points: [0, 1]),
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      scroll.jumpTo(300);
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(400, 0.5));
    });
  });

  group('markers', () {
    testWidgets('paint without errors for pinned and unpinned scenes', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        app(
          CustomScrollView(
            controller: scroll,
            slivers: const [
              SliverScrollScene(
                markers: SceneMarkers(label: 'hero'),
                pinExtent: 600,
                child: SizedBox.expand(),
              ),
              SliverScrollScene(
                markers: SceneMarkers.defaults,
                start: ScenePosition.top(0.8),
                end: ScenePosition.top(0.2),
                child: SizedBox(height: 300),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      );
      scroll.jumpTo(300);
      await tester.pump();
      scroll.jumpTo(1500);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('ScrollScene (box)', () {
    testWidgets('pins inside a ListView and reports progress', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      const key = Key('pinned');
      await tester.pumpWidget(
        app(
          ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 1000),
              ScrollScene(
                pinExtent: 1200,
                controller: scene,
                child: const ColoredBox(color: Colors.blue, key: key),
              ),
              const SizedBox(height: 3000),
            ],
          ),
        ),
      );
      scroll.jumpTo(1000);
      await tester.pump();
      expect(tester.getSize(find.byKey(key)).height, 800);
      expect(tester.getTopLeft(find.byKey(key)).dy, 0);

      scroll.jumpTo(1600);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, 0);
      expect(scene.rawProgress, closeTo(0.5, 1e-9));

      scroll.jumpTo(2500);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dy, -300);
      expect(scene.rawProgress, 1);
      expect(scroll.position.maxScrollExtent, 1000 + 800 + 1200 + 3000 - 800);
    });

    testWidgets('unpinned progress inside SingleChildScrollView', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                const SizedBox(height: 1000),
                ScrollScene(
                  controller: scene,
                  start: const ScenePosition.top(0.8),
                  end: const ScenePosition.top(0.2),
                  child: const SizedBox(height: 400),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      );
      scroll.jumpTo(600);
      await tester.pump();
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      scroll.jumpTo(840);
      await tester.pump();
      expect(scene.rawProgress, 1);
    });

    testWidgets('hit testing follows the pinned child', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      var taps = 0;
      await tester.pumpWidget(
        app(
          ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 1000),
              ScrollScene(
                pinExtent: 1000,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => taps++,
                    child: const ColoredBox(
                      color: Colors.green,
                      child: SizedBox(width: 100, height: 100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3000),
            ],
          ),
        ),
      );
      scroll.jumpTo(1500);
      await tester.pump();
      await tester.tapAt(const Offset(200, 50));
      expect(taps, 1);
      await tester.tapAt(const Offset(200, 400));
      expect(taps, 1);
    });
  });

  group('builder / scope', () {
    testWidgets('builder receives the controller and scope resolves it', (
      tester,
    ) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      SceneController? fromBuilder;
      SceneController? fromScope;
      await tester.pumpWidget(
        app(
          slivers(
            controller: scroll,
            scene: SliverScrollScene(
              pinExtent: 500,
              builder: (context, scene) {
                fromBuilder = scene;
                return Builder(
                  builder: (context) {
                    fromScope = ScrollSceneScope.of(context);
                    return AnimatedBuilder(
                      animation: scene.progress,
                      builder: (_, _) => Text('${scene.progress.value}'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
      expect(fromBuilder, isNotNull);
      expect(identical(fromBuilder, fromScope), isTrue);
      scroll.jumpTo(1250);
      await tester.pump();
      expect(find.text('0.5'), findsOneWidget);
    });

    testWidgets('horizontal scenes work', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      const key = Key('pinned');
      await tester.pumpWidget(
        app(
          CustomScrollView(
            controller: scroll,
            scrollDirection: Axis.horizontal,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(width: 500)),
              SliverScrollScene(
                pinExtent: 600,
                controller: scene,
                child: const ColoredBox(color: Colors.red, key: key),
              ),
              const SliverToBoxAdapter(child: SizedBox(width: 2000)),
            ],
          ),
        ),
      );
      scroll.jumpTo(800);
      await tester.pump();
      expect(tester.getTopLeft(find.byKey(key)).dx, 0);
      expect(tester.getSize(find.byKey(key)).width, 400);
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
    });

    testWidgets('reverse scroll direction pins at the bottom', (tester) async {
      await setSize(tester);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final scene = SceneController();
      addTearDown(scene.dispose);
      const key = Key('pinned');
      await tester.pumpWidget(
        app(
          CustomScrollView(
            controller: scroll,
            reverse: true,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
              SliverScrollScene(
                pinExtent: 600,
                controller: scene,
                child: const ColoredBox(color: Colors.red, key: key),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      );
      scroll.jumpTo(1300);
      await tester.pump();
      expect(tester.getBottomLeft(find.byKey(key)).dy, 800);
      expect(scene.rawProgress, closeTo(0.5, 1e-9));
      scroll.jumpTo(1900);
      await tester.pump();
      expect(tester.getBottomLeft(find.byKey(key)).dy, 800 + 300);
    });
  });
}
