import 'dart:ui';

import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart' show TextStyle, FontWeight;

/// "+40" / "Combo x2" text that floats up and fades out.
class FloatingText extends PositionComponent {
  FloatingText(this.text, Vector2 at, this.color, this.fontSize)
      : super(position: at, anchor: Anchor.center, priority: 50);

  final String text;
  final Color color;
  final double fontSize;
  double _life = 1;

  @override
  void update(double dt) {
    _life -= dt / 1.1;
    position.y -= dt * fontSize * 1.5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: _life.clamp(0.0, 1.0)),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
