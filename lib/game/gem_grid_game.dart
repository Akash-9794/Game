import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../logic/tray_game.dart';
import 'board_component.dart';
import 'floating_text.dart';
import 'gem_painter.dart';
import 'piece_component.dart';

/// Flame rendering layer: draws the board and the tray, and turns drags into
/// calls on [logic]. All rules live in lib/logic/; the score bar and menus
/// are Flutter widgets in lib/ui/.
class GemGridGame extends FlameGame {
  GemGridGame({required this.logic, this.onMove});

  static const Color background = GemPalette.background;

  /// The rules for the current mode (Classic or Adventure).
  final TrayGame logic;

  /// Called after every successful placement.
  final void Function(PlaceResult result)? onMove;

  late final BoardComponent _board;
  final List<PieceComponent> _pieces = [];

  // Layout, recomputed on resize.
  Vector2 boardOrigin = Vector2.zero();
  double boardCellSize = 0;
  Rect _trayRect = Rect.zero;

  @override
  Color backgroundColor() => background;

  @override
  Future<void> onLoad() async {
    _board = BoardComponent(() => logic.board);
    add(_board);
    _layout(size);
    _rebuildTray();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _layout(size);
      _rebuildTray();
    }
  }

  /// Portrait column, centred (on wide screens it stays phone-shaped).
  void _layout(Vector2 size) {
    const margin = 16.0;
    final playW = size.x.clamp(0.0, size.y * 0.8).toDouble();
    final left = (size.x - playW) / 2;
    final boardSize =
        (playW - margin * 2).clamp(0.0, size.y * 0.64).toDouble();

    boardCellSize = boardSize / 9;
    boardOrigin = Vector2(left + (playW - boardSize) / 2, margin);
    _board
      ..position = boardOrigin
      ..size = Vector2.all(boardSize);

    final trayTop = boardOrigin.y + boardSize + margin * 1.5;
    _trayRect = Rect.fromLTWH(left, trayTop, playW,
        (size.y - trayTop - margin).clamp(60.0, 400.0).toDouble());
  }

  void _rebuildTray() {
    removeAll(_pieces);
    _pieces.clear();
    final slotW = _trayRect.width / 3;
    final cell = [
      boardCellSize * 0.6,
      slotW / 5.5,
      _trayRect.height / 5.5,
    ].reduce((a, b) => a < b ? a : b);
    for (var i = 0; i < logic.tray.length; i++) {
      final piece = logic.tray[i];
      if (piece == null) continue;
      final pc = PieceComponent(
        trayIndex: i,
        piece: piece,
        slotPosition: Vector2(_trayRect.left + slotW * i, _trayRect.top),
        slotSize: Vector2(slotW, _trayRect.height),
        trayCellSize: cell,
      );
      _pieces.add(pc);
      add(pc);
    }
  }

  /// Call after the logic was restarted from outside (e.g. "Play again").
  void refresh() {
    _board.preview = null;
    _board.clearAnimations();
    removeWhere((c) => c is FloatingText);
    _rebuildTray();
  }

  /// Called while a piece is being dragged: update the board preview.
  void onPieceDragged(PieceComponent pc) {
    final (row, col) = pc.targetCell;
    final valid = logic.canPlace(pc.trayIndex, row, col);
    final (rows, cols) = valid
        ? logic.board.linesCompletedBy(pc.shape, row, col)
        : (const <int>[], const <int>[]);
    _board.preview = PlacementPreview(pc.piece, row, col, valid, rows, cols);
  }

  /// Called when a drag ends. Places the piece if it fits.
  void onPieceDropped(PieceComponent pc, {required bool place}) {
    _board.preview = null;
    if (!place) return;
    final (row, col) = pc.targetCell;

    // Remember what is in the lines that will clear, for the pop animation.
    final (rowsToClear, colsToClear) = logic.canPlace(pc.trayIndex, row, col)
        ? logic.board.linesCompletedBy(pc.shape, row, col)
        : (const <int>[], const <int>[]);
    final burst = <(int, int, int, bool)>[];
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (!rowsToClear.contains(r) && !colsToClear.contains(c)) continue;
        final placedHere = pc.shape.cells.contains((r - row, c - col));
        final gem = logic.board.gemAt(r, c) ?? (placedHere ? pc.piece.gem : null);
        if (gem != null) burst.add((r, c, gem, logic.board.isTarget(r, c)));
      }
    }

    final result = logic.place(pc.trayIndex, row, col);
    if (result == null) return; // Didn't fit: piece returns to the tray.

    _board.burst(burst);
    _showPoints(result, row, col, pc.shape);
    _rebuildTray();
    onMove?.call(result);
  }

  void _showPoints(PlaceResult result, int row, int col, Shape shape) {
    final center = boardOrigin +
        Vector2((col + shape.cols / 2) * boardCellSize,
            (row + shape.rows / 2) * boardCellSize);
    add(FloatingText('+${result.pointsGained}', center, GemPalette.text,
        boardCellSize * 0.7));
    if (result.clearedLines > 0) {
      final label = result.combo > 1
          ? 'Combo x${result.combo}!'
          : result.clearedLines > 1
              ? '${result.clearedLines} lines!'
              : 'Nice!';
      add(FloatingText(label, center - Vector2(0, boardCellSize),
          GemPalette.gold, boardCellSize * 0.8));
    }
  }
}
