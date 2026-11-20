import 'dart:ui';

import 'package:flame/components.dart';

import '../logic/tray_game.dart';
import 'gem_painter.dart';

/// Where a dragged piece would land, for the preview.
class PlacementPreview {
  final Piece piece;
  final int row;
  final int col;
  final bool valid;
  final List<int> rowsToClear;
  final List<int> colsToClear;

  const PlacementPreview(this.piece, this.row, this.col, this.valid,
      this.rowsToClear, this.colsToClear);
}

class _Burst {
  final int row, col, gem;
  final bool target;
  double t = 1; // 1 → 0
  _Burst(this.row, this.col, this.gem, this.target);
}

/// Draws the 9x9 board from [Board] state. Rendering only.
class BoardComponent extends PositionComponent {
  BoardComponent(this.boardOf);

  /// Reads the current board (it is replaced on restart).
  final Board Function() boardOf;

  PlacementPreview? preview;
  final List<_Burst> _bursts = [];
  final Paint _paint = Paint();

  double get cellSize => size.x / Board.size;
  double get _gap => cellSize * 0.08;

  /// Top-left of cell ([row], [col]) in game coordinates.
  Vector2 cellTopLeft(int row, int col) =>
      position + Vector2(col * cellSize, row * cellSize);

  /// Plays the "pop" animation for cells that were just cleared.
  void burst(List<(int, int, int, bool)> cells) {
    for (final (r, c, g, target) in cells) {
      _bursts.add(_Burst(r, c, g, target));
    }
  }

  void clearAnimations() => _bursts.clear();

  double _time = 0;

  @override
  void update(double dt) {
    _time += dt;
    for (final b in _bursts) {
      b.t -= dt * 3;
    }
    _bursts.removeWhere((b) => b.t <= 0);
  }

  Rect _cellRect(int r, int c, {double shrink = 0}) {
    final s = cellSize;
    final g = _gap + shrink;
    return Rect.fromLTWH(c * s + g, r * s + g, s - 2 * g, s - 2 * g);
  }

  @override
  void render(Canvas canvas) {
    final board = boardOf();
    final p = preview;

    _paint.color = GemPalette.boardBack;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-_gap * 2, -_gap * 2, size.x + _gap * 4,
              size.y + _gap * 4),
          Radius.circular(cellSize * 0.3)),
      _paint,
    );

    final previewCells = <(int, int)>{
      if (p != null && p.valid)
        for (final (r, c) in p.piece.shape.cells) (p.row + r, p.col + c),
    };

    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        final rect = _cellRect(r, c);
        final gem = board.gemAt(r, c);
        final clearing = p != null &&
            p.valid &&
            (p.rowsToClear.contains(r) || p.colsToClear.contains(c));

        if (gem != null) {
          // Lines about to clear take the dragged piece's colour.
          drawGem(canvas, rect,
              GemPalette.gem(clearing ? p.piece.gem : gem));
          if (board.isTarget(r, c)) {
            drawTargetMark(canvas, rect, pulse: _time);
          }
        } else if (previewCells.contains((r, c))) {
          drawGem(canvas, rect, GemPalette.gem(p!.piece.gem),
              opacity: clearing ? 0.9 : 0.4);
        } else {
          _paint.color = GemPalette.emptyCell;
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.15)),
              _paint);
        }
      }
    }

    // Cleared cells shrink and fade away.
    for (final b in _bursts) {
      final shrink = (1 - b.t) * cellSize * 0.35;
      final rect = _cellRect(b.row, b.col, shrink: shrink);
      drawGem(canvas, rect, GemPalette.gem(b.gem), opacity: b.t);
      if (b.target) drawTargetMark(canvas, rect, opacity: b.t);
    }
  }
}
