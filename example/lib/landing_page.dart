import 'package:flutter/material.dart';
import 'package:scroll_scene/scroll_scene.dart';

import 'scenes/gallery_scene.dart';
import 'scenes/hero_scene.dart';
import 'scenes/phone_scene.dart';
import 'scenes/reveal_scene.dart';
import 'scenes/snap_scene.dart';
import 'theme.dart';

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
