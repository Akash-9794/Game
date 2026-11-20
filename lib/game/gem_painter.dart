import 'dart:math' as math;
import 'dart:ui';

/// Colours and drawing for gem blocks. Rendering only — no game rules.
class GemPalette {
  static const Color background = Color(0xFF12121C);
  static const Color boardBack = Color(0xFF1E1E2E);
  static const Color emptyCell = Color(0xFF2A2A3D);
  static const Color text = Color(0xFFFFFFFF);
  static const Color subtleText = Color(0xFF9A9AB5);
  static const Color gold = Color(0xFFFFC94D);
  static const Color panel = Color(0xFF242436);

  static const List<Color> gems = [
    Color(0xFFE5395B), // ruby
    Color(0xFFF5A623), // amber
    Color(0xFF2ECC71), // emerald
    Color(0xFF3B82F6), // sapphire
    Color(0xFF9B59B6), // amethyst
    Color(0xFF1ABC9C), // topaz
    Color(0xFFFF6FB5), // rose
  ];

  static Color gem(int index) => gems[index % gems.length];
}

final Paint _fill = Paint();

/// Draws one gem block filling [rect]. [opacity] fades the whole block.
void drawGem(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
  final radius = Radius.circular(rect.width * 0.18);
  final a = opacity.clamp(0.0, 1.0);

  // Darker base (gives a bevel at the bottom).
  _fill.color = Color.lerp(color, const Color(0xFF000000), 0.35)!
      .withValues(alpha: a);
  canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), _fill);

  // Main face.
  final face = Rect.fromLTRB(
      rect.left, rect.top, rect.right, rect.bottom - rect.height * 0.1);
  _fill.color = color.withValues(alpha: a);
  canvas.drawRRect(RRect.fromRectAndRadius(face, radius), _fill);

  // Shine on the upper half.
  final shine = Rect.fromLTRB(
    face.left + face.width * 0.12,
    face.top + face.height * 0.1,
    face.right - face.width * 0.12,
    face.top + face.height * 0.45,
  );
  _fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.28 * a);
  canvas.drawRRect(
      RRect.fromRectAndRadius(shine, Radius.circular(rect.width * 0.12)),
      _fill);
}

/// Draws the white diamond that marks an Adventure target gem.
/// [pulse] (seconds) makes it gently breathe so targets stand out.
void drawTargetMark(Canvas canvas, Rect rect,
    {double pulse = 0, double opacity = 1}) {
  final scale = 1 + 0.08 * math.sin(pulse * 4);
  final c = rect.center;
  final r = rect.width * 0.26 * scale;
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r * 0.75, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r * 0.75, c.dy)
    ..close();
  _fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.95 * opacity);
  canvas.drawPath(path, _fill);
  _fill.color = const Color(0xFF000000).withValues(alpha: 0.25 * opacity);
  canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * 0.75, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..close(),
      _fill);
}
