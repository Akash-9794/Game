import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../logic/tray_game.dart';
import 'gem_grid_game.dart';
import 'gem_painter.dart';

/// One piece in the tray. Drag it onto the board to place it.
class PieceComponent extends PositionComponent
    with DragCallbacks, HasGameReference<GemGridGame> {
  PieceComponent({
    required this.trayIndex,
    required this.piece,
    required Vector2 slotPosition,
    required Vector2 slotSize,
    required this.trayCellSize,
  }) : super(position: slotPosition, size: slotSize, priority: 10);

  final int trayIndex;
  final Piece piece;
  final double trayCellSize;

  bool _dragging = false;
  Vector2 _pointer = Vector2.zero();
  double _appear = 0; // 0 → 1 pop-in animation when dealt

  Shape get shape => piece.shape;

  /// Top-left of the dragged shape in game coordinates. The shape floats
  /// above the finger so the player can see where it goes.
  Vector2 get dragTopLeft {
    final cell = game.boardCellSize;
    return _pointer -
        Vector2(shape.cols * cell / 2, shape.rows * cell + cell * 1.2);
  }

  /// Board cell the shape would snap to right now.
  (int, int) get targetCell {
    final cell = game.boardCellSize;
    final rel = dragTopLeft - game.boardOrigin;
    return ((rel.y / cell).round(), (rel.x / cell).round());
  }

  @override
  void update(double dt) {
    if (_appear < 1) _appear = (_appear + dt * 5).clamp(0, 1);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.logic.isOver) return;
    _dragging = true;
    _pointer = event.canvasPosition.clone();
    priority = 100;
    game.onPieceDragged(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    _pointer = event.canvasEndPosition.clone();
    game.onPieceDragged(this);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finish();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    priority = 10;
    game.onPieceDropped(this, place: false);
  }

  void _finish() {
    if (!_dragging) return;
    _dragging = false;
    priority = 10;
    game.onPieceDropped(this, place: true);
  }

  @override
  void render(Canvas canvas) {
    final Vector2 topLeft;
    final double cell;
    if (_dragging) {
      cell = game.boardCellSize;
      topLeft = dragTopLeft - position; // local coordinates
    } else {
      cell = trayCellSize * (0.6 + 0.4 * _appear);
      topLeft = Vector2(
        (size.x - shape.cols * cell) / 2,
        (size.y - shape.rows * cell) / 2,
      );
    }
    final gap = cell * 0.08;
    final color = GemPalette.gem(piece.gem);
    final fits = game.logic.board.fitsAnywhere(shape);
    for (final (r, c) in shape.cells) {
      drawGem(
        canvas,
        Rect.fromLTWH(topLeft.x + c * cell + gap, topLeft.y + r * cell + gap,
            cell - 2 * gap, cell - 2 * gap),
        color,
        // Pieces that can't fit anywhere are dimmed.
        opacity: fits || _dragging ? 1 : 0.35,
      );
    }
  }
}
