import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/classic_game.dart';

final single = Piece(Shape.fromPattern(['X']), 0);
final bigSquare = Piece(Shape.fromPattern(['XXX', 'XXX', 'XXX']), 1);

void main() {
  test('starts with 3 pieces and not game over', () {
    final g = ClassicGame(random: Random(1));
    expect(g.tray.length, 3);
    expect(g.tray.every((p) => p != null), isTrue);
    expect(g.isGameOver, isFalse);
    expect(g.score, 0);
  });

  test('placing a piece removes it from the tray', () {
    final g = ClassicGame(dealer: () => single);
    expect(g.place(0, 0, 0), isNotNull);
    expect(g.tray[0], isNull);
    expect(g.board.gemAt(0, 0), 0);
  });

  test('a used tray slot cannot be placed again', () {
    final g = ClassicGame(dealer: () => single);
    g.place(0, 0, 0);
    expect(g.place(0, 1, 1), isNull);
  });

  test('3 new pieces are dealt after all 3 are placed', () {
    final g = ClassicGame(dealer: () => single);
    g.place(0, 0, 0);
    g.place(1, 0, 1);
    g.place(2, 0, 2);
    expect(g.tray.every((p) => p != null), isTrue);
  });

  test('invalid placement returns null and changes nothing', () {
    final g = ClassicGame(dealer: () => bigSquare);
    expect(g.place(0, 7, 7), isNull);
    expect(g.tray[0], isNotNull);
    expect(g.score, 0);
  });

  test('game over when no remaining piece fits', () {
    var dealt = 0;
    final g = ClassicGame(dealer: () => dealt++ < 3 ? single : bigSquare);
    // Checkerboard of blocks: no line is full and no 3x3 square fits.
    // Leave 3 checkerboard cells free for the 3 singles in the tray.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if ((r + c).isEven && !(r == 0 && c <= 4)) g.board.place(single.shape, r, c);
      }
    }
    g.place(0, 0, 0);
    g.place(1, 0, 2);
    expect(g.isGameOver, isFalse);
    g.place(2, 0, 4); // tray empty -> 3x3 squares dealt, none fit
    expect(g.tray.every((p) => p == bigSquare), isTrue);
    expect(g.isGameOver, isTrue);
    expect(g.place(0, 0, 1), isNull);
  });

  test('restart clears the board and score', () {
    final g = ClassicGame(dealer: () => single);
    g.place(0, 4, 4);
    g.restart();
    expect(g.score, 0);
    expect(g.board.isFilled(4, 4), isFalse);
    expect(g.isGameOver, isFalse);
  });
}
