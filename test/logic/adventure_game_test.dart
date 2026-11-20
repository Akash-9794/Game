import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/adventure_game.dart';

final single = Piece(Shape.fromPattern(['X']), 0);
final row3 = Piece(Shape.fromPattern(['XXX']), 2);
final bigSquare = Piece(Shape.fromPattern(['XXX', 'XXX', 'XXX']), 1);

Level makeLevel({int score = 0, List<(int, int)> targets = const [], int moves = 10}) =>
    Level(number: 1, targetScore: score, targets: targets, moves: moves);

void main() {
  test('targets are placed on the board at the start', () {
    final g = AdventureGame(makeLevel(targets: [(2, 3), (5, 5)]), dealer: () => single);
    expect(g.targetsLeft, 2);
    expect(g.board.isTarget(2, 3), isTrue);
    expect(g.board.isFilled(5, 5), isTrue);
    expect(g.status, LevelStatus.playing);
  });

  test('each placement uses one move', () {
    final g = AdventureGame(makeLevel(score: 999), dealer: () => single);
    g.place(0, 0, 0);
    expect(g.movesLeft, 9);
    expect(g.movesUsed, 1);
  });

  test('clearing the line with the target gem wins a gems-only level', () {
    final g = AdventureGame(makeLevel(targets: [(0, 8)]), dealer: () => row3);
    g.place(0, 0, 0);
    g.place(1, 0, 3);
    expect(g.status, LevelStatus.playing);
    // Row 0 needs cells 6 and 7; the target sits in cell 8.
    final g2 = AdventureGame(makeLevel(targets: [(0, 8)]),
        dealer: () => Piece(Shape.fromPattern(['XX']), 3));
    g2.place(0, 0, 0);
    g2.place(1, 0, 2);
    g2.place(2, 0, 4);
    expect(g2.status, LevelStatus.playing);
    final r = g2.place(0, 0, 6);
    expect(r!.clearedTargets, 1);
    expect(g2.targetsLeft, 0);
    expect(g2.status, LevelStatus.won);
    expect(g2.isOver, isTrue);
  });

  test('reaching the target score wins a score-only level', () {
    final g = AdventureGame(makeLevel(score: 3), dealer: () => row3);
    g.place(0, 4, 0);
    expect(g.status, LevelStatus.won);
    expect(g.stars, 3);
  });

  test('running out of moves loses', () {
    final g = AdventureGame(makeLevel(score: 999, moves: 2), dealer: () => single);
    g.place(0, 0, 0);
    expect(g.status, LevelStatus.playing);
    g.place(1, 5, 5);
    expect(g.status, LevelStatus.lost);
    expect(g.lossReason, LossReason.outOfMoves);
    expect(g.place(2, 7, 7), isNull, reason: 'no moves after the level ends');
  });

  test('no space for any piece loses', () {
    var dealt = 0;
    final g = AdventureGame(makeLevel(score: 999, moves: 99),
        dealer: () => dealt++ < 3 ? single : bigSquare);
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if ((r + c).isEven && !(r == 0 && c <= 4)) g.board.place(single.shape, r, c);
      }
    }
    g.place(0, 0, 0);
    g.place(1, 0, 2);
    g.place(2, 0, 4);
    expect(g.status, LevelStatus.lost);
    expect(g.lossReason, LossReason.noSpace);
  });

  test('stars depend on moves left', () {
    // 10 moves; win on move 7 → 3 left (30%) → 2 stars.
    final g = AdventureGame(makeLevel(score: 7, moves: 10), dealer: () => single);
    for (var i = 0; i < 7; i++) {
      g.place(i % 3, i, i);
    }
    expect(g.status, LevelStatus.won);
    expect(g.stars, 2);
  });

  test('restart resets moves, targets and status', () {
    final g = AdventureGame(makeLevel(score: 999, targets: [(4, 4)], moves: 1),
        dealer: () => single);
    g.place(0, 0, 0);
    expect(g.status, LevelStatus.lost);
    g.restart();
    expect(g.status, LevelStatus.playing);
    expect(g.movesLeft, 1);
    expect(g.targetsLeft, 1);
    expect(g.score, 0);
  });
}
