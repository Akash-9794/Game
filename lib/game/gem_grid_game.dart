import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../logic/classic_game.dart';
import '../services/best_score_store.dart';
import 'board_component.dart';
import 'floating_text.dart';
import 'gem_painter.dart';
import 'piece_component.dart';

/// Flame rendering layer for Classic mode. It only draws and forwards input
/// to [ClassicGame]; all rules live in lib/logic/.
class GemGridGame extends FlameGame {
  GemGridGame({ClassicGame? logic, BestScoreStore? store})
      : logic = logic ?? ClassicGame(),
        _store = store ?? BestScoreStore();

  static const Color background = GemPalette.background;
  static const String gameOverOverlay = 'gameOver';

  final ClassicGame logic;
  final BestScoreStore _store;
  int bestScore = 0;

  late final BoardComponent _board;
  late final TextComponent _title;
  late final TextComponent _scoreText;
  late final TextComponent _bestText;
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
    _title = TextComponent(
      text: 'Gem Grid',
      anchor: Anchor.topCenter,
      textRenderer: _style(18, GemPalette.subtleText),
    );
    _scoreText = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      textRenderer: _style(44, GemPalette.text),
    );
    _bestText = TextComponent(
      text: 'BEST 0',
      anchor: Anchor.topLeft,
      textRenderer: _style(16, GemPalette.gems[1]),
    );
    addAll([_board, _title, _scoreText, _bestText]);
    _layout(size);
    _rebuildTray();

    bestScore = await _store.load();
    _updateHud();
  }

  TextPaint _style(double size, Color color) => TextPaint(
        style: TextStyle(
            color: color, fontSize: size, fontWeight: FontWeight.bold),
      );

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
    final playW = size.x.clamp(0.0, size.y * 0.62);
    final left = (size.x - playW) / 2;
    const margin = 16.0;
    final hudH = (size.y * 0.16).clamp(90.0, 160.0);
    final boardSize =
        (playW - margin * 2).clamp(0.0, size.y * 0.56).toDouble();

    boardCellSize = boardSize / 9;
    boardOrigin = Vector2(left + (playW - boardSize) / 2, hudH);
    _board
      ..position = boardOrigin
      ..size = Vector2.all(boardSize);

    _title.position = Vector2(size.x / 2, hudH * 0.1);
    _scoreText.position = Vector2(size.x / 2, hudH * 0.3);
    _bestText.position = Vector2(boardOrigin.x, hudH * 0.1);

    final trayTop = boardOrigin.y + boardSize + margin * 1.5;
    _trayRect = Rect.fromLTWH(
        left, trayTop, playW, (size.y - trayTop - margin).clamp(60, 400));
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

  void _updateHud() {
    _scoreText.text = '${logic.score}';
    _bestText.text = 'BEST $bestScore';
  }

  /// Called while a piece is being dragged: update the board preview.
  void onPieceDragged(PieceComponent pc) {
    final (row, col) = pc.targetCell;
    final valid = logic.canPlace(pc.trayIndex, row, col);
    final (rows, cols) = valid
        ? logic.board.linesCompletedBy(pc.shape, row, col)
        : (const <int>[], const <int>[]);
    _board.preview =
        PlacementPreview(pc.piece, row, col, valid, rows, cols);
  }

  /// Called when a drag ends. Places the piece if it fits.
  void onPieceDropped(PieceComponent pc, {required bool place}) {
    _board.preview = null;
    if (!place) return;
    final (row, col) = pc.targetCell;

    // Remember gems in lines that will clear, for the pop animation.
    final before = [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++) (r, c, logic.board.gemAt(r, c)),
    ];
    final result = logic.place(pc.trayIndex, row, col);
    if (result == null) return; // Didn't fit: piece returns to the tray.

    final burst = <(int, int, int)>[];
    for (final (r, c, gem) in before) {
      final inLine =
          result.clearedRows.contains(r) || result.clearedCols.contains(c);
      if (!inLine) continue;
      final placedHere = pc.shape.cells.contains((r - row, c - col));
      final g = gem ?? (placedHere ? pc.piece.gem : null);
      if (g != null) burst.add((r, c, g));
    }
    _board.burst(burst);

    _showPoints(result, row, col, pc.shape);
    if (logic.score > bestScore) {
      bestScore = logic.score;
      _store.save(bestScore);
    }
    _updateHud();
    _rebuildTray();

    if (logic.isGameOver) {
      overlays.add(gameOverOverlay);
    }
  }

  void _showPoints(PlaceResult result, int row, int col, Shape shape) {
    final center = boardOrigin +
        Vector2((col + shape.cols / 2) * boardCellSize,
            (row + shape.rows / 2) * boardCellSize);
    add(FloatingText('+${result.pointsGained}', center,
        GemPalette.text, boardCellSize * 0.7));
    if (result.clearedLines > 0) {
      final label = result.combo > 1
          ? 'Combo x${result.combo}!'
          : result.clearedLines > 1
              ? '${result.clearedLines} lines!'
              : 'Nice!';
      add(FloatingText(label, center - Vector2(0, boardCellSize),
          GemPalette.gems[1], boardCellSize * 0.8));
    }
  }

  void restart() {
    overlays.remove(gameOverOverlay);
    logic.restart();
    _updateHud();
    _rebuildTray();
  }
}
