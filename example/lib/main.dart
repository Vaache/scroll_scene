import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import 'landing_page.dart';
import 'theme.dart';

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
