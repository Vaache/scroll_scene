import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

/// Visual style for the debug marker overlay.
@immutable
class SceneMarkers {
  /// Creates a marker style.
  const SceneMarkers({
    this.startColor = const Color(0xFF2ECC71),
    this.endColor = const Color(0xFFE74C3C),
    this.scrollerColor = const Color(0xFF3498DB),
    this.pinColor = const Color(0x332ECC71),
    this.fontSize = 11,
    this.fontFamily,
    this.label,
  });

  /// Default markers.
  static const SceneMarkers defaults = SceneMarkers();

  /// Colour of the element start line.
  final Color startColor;

  /// Colour of the element end line.
  final Color endColor;

  /// Colour of the viewport (scroller) trigger lines.
  final Color scrollerColor;

  /// Fill of the pin range band.
  final Color pinColor;

  /// Label font size.
  final double fontSize;

  /// Label font family; null uses the platform default.
  final String? fontFamily;

  /// Optional scene name shown in the progress badge.
  final String? label;

  /// Copy with the given fields replaced.
  SceneMarkers copyWith({
    Color? startColor,
    Color? endColor,
    Color? scrollerColor,
    Color? pinColor,
    double? fontSize,
    String? fontFamily,
    String? label,
  }) => SceneMarkers(
    startColor: startColor ?? this.startColor,
    endColor: endColor ?? this.endColor,
    scrollerColor: scrollerColor ?? this.scrollerColor,
    pinColor: pinColor ?? this.pinColor,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: fontFamily ?? this.fontFamily,
    label: label ?? this.label,
  );

  @override
  bool operator ==(Object other) =>
      other is SceneMarkers &&
      other.startColor == startColor &&
      other.endColor == endColor &&
      other.scrollerColor == scrollerColor &&
      other.pinColor == pinColor &&
      other.fontSize == fontSize &&
      other.fontFamily == fontFamily &&
      other.label == label;

  @override
  int get hashCode => Object.hash(
    startColor,
    endColor,
    scrollerColor,
    pinColor,
    fontSize,
    fontFamily,
    label,
  );
}

/// Everything the overlay needs, in main-axis coordinates relative to the
/// paint origin.
@immutable
class SceneMarkerLayout {
  /// Creates marker layout data.
  const SceneMarkerLayout({
    required this.axisDirection,
    required this.crossExtent,
    required this.contentStart,
    required this.contentExtent,
    required this.triggerStart,
    required this.triggerEnd,
    required this.scrollerStart,
    required this.scrollerEnd,
    required this.pinExtent,
    required this.progress,
  });

  /// Direction the main axis grows in.
  final AxisDirection axisDirection;

  /// Cross-axis size available for drawing.
  final double crossExtent;

  /// Main-axis position of the element's leading edge.
  final double contentStart;

  /// Main-axis extent of the element.
  final double contentExtent;

  /// Element-side start trigger position.
  final double triggerStart;

  /// Element-side end trigger position.
  final double triggerEnd;

  /// Viewport-side start trigger position.
  final double scrollerStart;

  /// Viewport-side end trigger position.
  final double scrollerEnd;

  /// Pin distance, 0 when unpinned.
  final double pinExtent;

  /// Current raw progress.
  final double progress;
}

/// Paints GSAP-style start/end/scroller lines and a progress badge.
class SceneMarkerPainter {
  /// Creates a painter.
  SceneMarkerPainter(this.style);

  /// Style to paint with.
  final SceneMarkers style;

  final Map<String, TextPainter> _labels = {};

  TextPainter _label(String text, Color color) => _labels.putIfAbsent(
    '$text/${color.toARGB32()}',
    () => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: style.fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: style.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(),
  );

  /// Paints the overlay at [origin].
  void paint(Canvas canvas, Offset origin, SceneMarkerLayout layout) {
    final vertical = axisDirectionToAxis(layout.axisDirection) == Axis.vertical;
    final reversed = axisDirectionIsReversed(layout.axisDirection);
    final cross = layout.crossExtent;

    Offset at(double main, double crossPos) {
      final m = reversed ? -main : main;
      return vertical
          ? origin + Offset(crossPos, m)
          : origin + Offset(m, crossPos);
    }

    void line(double main, Color color, String text, {bool full = false}) {
      final paint =
          Paint()
            ..color = color
            ..strokeWidth = 1.5;
      final length = full ? cross : 56.0;
      final start = cross - length;
      canvas.drawLine(at(main, start), at(main, cross), paint);
      final tp = _label(text, color);
      final pos =
          vertical
              ? at(main, cross - tp.width - 4) + const Offset(0, 2)
              : at(main, start) + const Offset(3, 0);
      tp.paint(canvas, pos);
    }

    if (layout.pinExtent > 0) {
      final a = at(layout.contentStart, cross - 6);
      final b = at(layout.contentStart + layout.pinExtent, cross);
      canvas.drawRect(Rect.fromPoints(a, b), Paint()..color = style.pinColor);
    }

    line(
      layout.scrollerStart,
      style.scrollerColor,
      'scroller-start',
      full: true,
    );
    if (layout.pinExtent == 0) {
      line(layout.scrollerEnd, style.scrollerColor, 'scroller-end', full: true);
    }
    line(layout.triggerStart, style.startColor, 'start');
    line(layout.triggerEnd, style.endColor, 'end');

    final badge = _label(
      '${style.label == null ? '' : '${style.label} '}'
      '${(layout.progress * 100).toStringAsFixed(0).padLeft(3)}%',
      const Color(0xFFFFFFFF),
    );
    final badgePos = at(layout.contentStart, 0) + const Offset(6, 6);
    final rect = Rect.fromLTWH(
      badgePos.dx,
      badgePos.dy,
      badge.width + 10,
      badge.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = const Color(0xCC111111),
    );
    badge.paint(canvas, badgePos + const Offset(5, 3));
  }

  /// Releases cached text layouts.
  void dispose() {
    for (final tp in _labels.values) {
      tp.dispose();
    }
    _labels.clear();
  }
}
