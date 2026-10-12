import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_scene/scroll_scene.dart';
import 'package:scroll_scene_example/main.dart';

/// Renders README media frame by frame. Skipped unless `SCENE_MEDIA_DIR`
/// points at an output directory; `tool/render_media.sh` turns the frames
/// into GIF / MP4.
void main() {
  final dir = Platform.environment['SCENE_MEDIA_DIR'];
  const size = Size(390, 844);
  const fps = 30;
  const frame = Duration(microseconds: 1000000 ~/ fps);
  final key = GlobalKey();
  var fontsLoaded = false;

  Future<void> loadFonts(WidgetTester tester) async {
    if (fontsLoaded) return;
    fontsLoaded = true;
    final root =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.path;
    final fonts = Directory('$root/bin/cache/artifacts/material_fonts');
    await tester.runAsync(() async {
      final roboto = FontLoader('Roboto');
      for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
        final bytes =
            await File('${fonts.path}/Roboto-$weight.ttf').readAsBytes();
        roboto.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await roboto.load();
      final icons = FontLoader('MaterialIcons');
      final bytes =
          await File('${fonts.path}/MaterialIcons-Regular.otf').readAsBytes();
      icons.addFont(Future.value(ByteData.sublistView(bytes)));
      await icons.load();
    });
  }

  Future<void> snap(WidgetTester tester, String path) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage());
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  Widget stage(ScrollController controller, {bool markers = false}) =>
      RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: const MediaQueryData(size: size, devicePixelRatio: 1),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(fontFamily: 'Roboto'),
            home: Scaffold(
              body: LandingPage(
                controller: controller,
                markers:
                    markers ? const SceneMarkers(fontFamily: 'Roboto') : null,
              ),
            ),
          ),
        ),
      );

  Future<void> setup(WidgetTester tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadFonts(tester);
  }

  double startOf(WidgetTester tester, Type scene) {
    final ro =
        tester.renderObject(find.byType(scene, skipOffstage: false))
            as RenderSliverScrollScene;
    return ro.constraints.precedingScrollExtent;
  }

  Future<double> locate(
    WidgetTester tester,
    ScrollController scroll,
    Type scene,
  ) async {
    final max = scroll.position.maxScrollExtent;
    for (var offset = 0.0; offset <= max; offset += size.height / 2) {
      scroll.jumpTo(offset);
      await tester.pump();
      final ro =
          tester.renderObject(find.byType(scene, skipOffstage: false))
              as RenderSliverScrollScene;
      if (ro.geometry != null && ro.geometry!.paintExtent > 0) {
        return startOf(tester, scene);
      }
    }
    throw StateError('$scene never became visible');
  }

  Future<int> record(
    WidgetTester tester,
    String name,
    int startIndex,
    Future<void> Function(Future<void> Function() capture) body,
  ) async {
    final out = Directory('$dir/$name')..createSync(recursive: true);
    var n = startIndex;
    await body(() async {
      await snap(tester, '${out.path}/${n.toString().padLeft(4, '0')}.png');
      n++;
    });
    return n;
  }

  Future<void> scrollThrough(
    WidgetTester tester,
    ScrollController scroll,
    Future<void> Function() capture, {
    required double from,
    required double to,
    required Duration duration,
    Duration hold = const Duration(milliseconds: 700),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    final frames = duration.inMicroseconds ~/ frame.inMicroseconds;
    for (var f = 0; f <= frames; f++) {
      final t = curve.transform(f / frames);
      scroll.jumpTo(from + (to - from) * t);
      await tester.pump(frame);
      await capture();
    }
    final holdFrames = hold.inMicroseconds ~/ frame.inMicroseconds;
    for (var f = 0; f < holdFrames; f++) {
      await tester.pump(frame);
      await capture();
    }
  }

  testWidgets('hero', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll));
    await record(tester, 'hero', 0, (capture) async {
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: 0,
        to: 1400,
        duration: const Duration(milliseconds: 3200),
      );
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: 1400,
        to: 1400 + 500,
        duration: const Duration(milliseconds: 900),
        hold: const Duration(milliseconds: 400),
      );
    });
  }, skip: dir == null);

  testWidgets('phone', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll));
    final start = await locate(tester, scroll, PhoneScene);
    scroll.jumpTo(start - 400);
    await tester.pump();
    await record(tester, 'phone', 0, (capture) async {
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: start - 400,
        to: start + 1600,
        duration: const Duration(milliseconds: 4200),
        hold: const Duration(milliseconds: 900),
      );
    });
  }, skip: dir == null);

  testWidgets('gallery', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll));
    final start = await locate(tester, scroll, GalleryScene);
    scroll.jumpTo(start - 300);
    await tester.pump();
    await record(tester, 'gallery', 0, (capture) async {
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: start - 300,
        to: start + 1800,
        duration: const Duration(milliseconds: 3800),
      );
    });
  }, skip: dir == null);

  testWidgets('reveal', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll));
    final start = await locate(tester, scroll, RevealScene);
    final from = start - size.height;
    scroll.jumpTo(from);
    await tester.pump();
    await record(tester, 'reveal', 0, (capture) async {
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: from,
        to: start - 120,
        duration: const Duration(milliseconds: 2600),
        hold: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
      );
    });
  }, skip: dir == null);

  testWidgets('snap', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll));
    final start = await locate(tester, scroll, SnapScene);
    scroll.jumpTo(start);
    await tester.pump();
    Future<void> dragAndRelease(
      Future<void> Function() capture,
      double distance,
    ) async {
      final gesture = await tester.startGesture(const Offset(195, 600));
      const steps = 22;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(Offset(0, -distance / steps));
        await tester.pump(frame);
        await capture();
      }
      await gesture.up();
      for (var i = 0; i < 36; i++) {
        await tester.pump(frame);
        await capture();
      }
    }

    await record(tester, 'snap', 0, (capture) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(frame);
        await capture();
      }
      await dragAndRelease(capture, 380);
      await dragAndRelease(capture, 330);
      await dragAndRelease(capture, -450);
    });
    expect(scroll.offset, closeTo(start + 600, 1));
  }, skip: dir == null);

  testWidgets('markers', (tester) async {
    await setup(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(stage(scroll, markers: true));
    final start = await locate(tester, scroll, RevealScene);
    final heroStart = startOf(tester, HeroScene) + 0;
    scroll.jumpTo(heroStart + 1100);
    await tester.pump();
    await record(tester, 'markers', 0, (capture) async {
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: heroStart + 1100,
        to: heroStart + 1400 + 500,
        duration: const Duration(milliseconds: 2200),
        hold: const Duration(milliseconds: 300),
      );
      await scrollThrough(
        tester,
        scroll,
        capture,
        from: start - size.height,
        to: start - 100,
        duration: const Duration(milliseconds: 2400),
        hold: const Duration(milliseconds: 600),
      );
    });
  }, skip: dir == null);
}
