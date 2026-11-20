// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'dart:math';

import 'board.dart';

export 'board.dart';

/// A shape waiting in the tray, with the gem colour it will have.
class Piece {
  final Shape shape;
  final int gem;
  const Piece(this.shape, this.gem);
}

/// Number of different gem colours.
const int gemColorCount = 7;

/// Rules shared by every mode: a board plus a tray of 3 pieces. When all 3
/// are placed, 3 new ones are dealt.
abstract class TrayGame {
  static const int piecesPerTurn = 3;

  TrayGame({Random? random, this.dealer}) : random = random ?? Random();

  final Random random;

  /// Lets tests choose exactly which pieces are dealt.
  final Piece Function()? dealer;

  Board board = Board();
  List<Piece?> tray = [];

  /// True when none of the pieces left in the tray fits on the board.
  bool noMovesLeft = false;

  int get score => board.score;
  int get combo => board.combo;

  /// True once the game has ended (won or lost). No more moves are accepted.
  bool get isOver;

  /// Builds the starting board. Modes can override to pre-place gems.
  Board createBoard() => Board();

  /// Called after every successful placement (after any new deal).
  void afterPlace(PlaceResult result) {}

  /// Starts (or restarts) the game from scratch.
  void start() {
    board = createBoard();
    noMovesLeft = false;
    _deal();
  }

  Piece randomPiece() => Piece(
        allShapes[random.nextInt(allShapes.length)],
        random.nextInt(gemColorCount),
      );

  void _deal() {
    tray = List.generate(piecesPerTurn, (_) => (dealer ?? randomPiece)());
    _checkMoves();
  }

  void _checkMoves() {
    noMovesLeft =
        !tray.any((p) => p != null && board.fitsAnywhere(p.shape));
  }

  bool canPlace(int trayIndex, int row, int col) {
    if (isOver || trayIndex < 0 || trayIndex >= tray.length) return false;
    final piece = tray[trayIndex];
    return piece != null && board.canPlace(piece.shape, row, col);
  }

  /// Places the tray piece at [trayIndex]. Returns null if it doesn't fit.
  PlaceResult? place(int trayIndex, int row, int col) {
    if (!canPlace(trayIndex, row, col)) return null;
    final piece = tray[trayIndex]!;
    final result = board.place(piece.shape, row, col, gem: piece.gem);
    tray[trayIndex] = null;
    if (tray.every((p) => p == null)) {
      _deal();
    } else {
      _checkMoves();
    }
    afterPlace(result);
    return result;
  }
}
