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

/// Classic mode: endless play. 3 pieces per turn; when all 3 are placed,
/// 3 new ones are dealt. Game over when no remaining piece fits.
class ClassicGame {
  static const int piecesPerTurn = 3;

  final Random _random;
  /// Lets tests choose exactly which pieces are dealt.
  final Piece Function()? dealer;

  Board board = Board();
  List<Piece?> tray = [];
  bool isGameOver = false;

  ClassicGame({Random? random, this.dealer}) : _random = random ?? Random() {
    _deal();
  }

  int get score => board.score;
  int get combo => board.combo;

  void restart() {
    board = Board();
    isGameOver = false;
    _deal();
  }

  Piece _randomPiece() => Piece(
        allShapes[_random.nextInt(allShapes.length)],
        _random.nextInt(gemColorCount),
      );

  void _deal() {
    tray = List.generate(piecesPerTurn, (_) => (dealer ?? _randomPiece)());
    _checkGameOver();
  }

  bool canPlace(int trayIndex, int row, int col) {
    final piece = tray[trayIndex];
    return !isGameOver &&
        piece != null &&
        board.canPlace(piece.shape, row, col);
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
      _checkGameOver();
    }
    return result;
  }

  void _checkGameOver() {
    isGameOver = !tray.any((p) => p != null && board.fitsAnywhere(p.shape));
  }
}
