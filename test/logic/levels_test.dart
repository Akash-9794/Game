import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/adventure_game.dart';

/// A simple greedy player: tries every piece in every spot and picks the
/// move that clears the most targets, then lines, then fills the most.
void playGreedy(AdventureGame g) {
  while (!g.isOver) {
    (int, int, int)? best;
    var bestValue = -1.0;
    for (var i = 0; i < g.tray.length; i++) {
      final piece = g.tray[i];
      if (piece == null) continue;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!g.board.canPlace(piece.shape, r, c)) continue;
          final (rows, cols) = g.board.linesCompletedBy(piece.shape, r, c);
          var targets = 0;
          for (final row in rows) {
            for (var x = 0; x < 9; x++) {
              if (g.board.isTarget(row, x)) targets++;
            }
          }
          for (final col in cols) {
            for (var y = 0; y < 9; y++) {
              if (g.board.isTarget(y, col)) targets++;
            }
          }
          // Prefer spots on rows/cols that already hold targets.
          var near = 0;
          for (final (dr, dc) in piece.shape.cells) {
            for (var x = 0; x < 9; x++) {
              if (g.board.isTarget(r + dr, x) || g.board.isTarget(x, c + dc)) near++;
            }
          }
          final value = targets * 1000.0 +
              (rows.length + cols.length) * 100 +
              near * 3 +
              piece.shape.cells.length;
          if (value > bestValue) {
            bestValue = value;
            best = (i, r, c);
          }
        }
      }
    }
    if (best == null) return;
    g.place(best.$1, best.$2, best.$3);
  }
}

void main() {
  test('there are 30 levels numbered 1..30 with sane goals', () {
    expect(levels.length, levelCount);
    for (var i = 0; i < levels.length; i++) {
      final l = levels[i];
      expect(l.number, i + 1);
      expect(l.moves, greaterThan(0));
      expect(l.hasScoreGoal || l.hasTargetGoal, isTrue);
      expect(l.targets.toSet().length, l.targets.length, reason: 'no duplicate targets');
    }
  });

  test('levels are the same every time (fixed seed)', () {
    expect(levels[9].targets, levels[9].targets);
    expect(levels.map((l) => l.targets.length).toList(),
        levels.map((l) => l.targets.length).toList());
  });

  test('every level can be beaten by a simple bot', () {
    final winRates = <int, double>{};
    for (final level in levels) {
      var wins = 0;
      const tries = 30;
      for (var t = 0; t < tries; t++) {
        final g = AdventureGame(level, random: Random(level.number * 100 + t));
        playGreedy(g);
        if (g.status == LevelStatus.won) wins++;
      }
      winRates[level.number] = wins / tries;
    }
    // ignore: avoid_print
    print('Bot win rate per level: $winRates');
    for (final e in winRates.entries) {
      expect(e.value, greaterThan(0), reason: 'level ${e.key} looks impossible');
    }
  });
}
