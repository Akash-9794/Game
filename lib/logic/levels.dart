// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'dart:math';

/// One Adventure level. To win, reach [targetScore] AND clear every target
/// gem, using at most [moves] placements.
class Level {
  final int number;
  final int targetScore;
  final List<(int, int)> targets;
  final int moves;

  const Level({
    required this.number,
    required this.targetScore,
    required this.targets,
    required this.moves,
  });

  bool get hasScoreGoal => targetScore > 0;
  bool get hasTargetGoal => targets.isNotEmpty;
}

const int levelCount = 30;

/// All Adventure levels. They are generated from a fixed formula and seed,
/// so every player gets exactly the same levels.
final List<Level> levels = List.unmodifiable(
  List.generate(levelCount, (i) => _buildLevel(i + 1)),
);

Level _buildLevel(int n) {
  // Levels 1-3 teach scoring, 4-6 teach target gems, then they mix.
  final kind = n <= 3
      ? 0 // score only
      : n <= 6
          ? 1 // gems only
          : n % 3 == 0
              ? 2 // both
              : n % 3 == 1
                  ? 0
                  : 1;

  final targetCount = kind == 0 ? 0 : min(2 + n ~/ 4, 9);
  final targetScore = kind == 1 ? 0 : 40 + n * 10;

  // Moves: enough room to reach the goal, slowly getting tighter.
  var moves = 10 + n ~/ 2;
  if (kind == 0) moves += n ~/ 2 + 2;
  if (kind != 0) moves += targetCount * 2;
  if (kind == 2) moves += 4;

  return Level(
    number: n,
    targetScore: targetScore,
    targets: _targetCells(n, targetCount),
    moves: moves,
  );
}

/// Picks [count] distinct cells for target gems, never filling a whole line.
List<(int, int)> _targetCells(int seed, int count) {
  final random = Random(seed * 7919);
  final cells = <(int, int)>{};
  final perRow = List.filled(9, 0), perCol = List.filled(9, 0);
  while (cells.length < count) {
    final r = random.nextInt(9), c = random.nextInt(9);
    // At most 2 targets per row/column keeps levels fair.
    if (cells.contains((r, c)) || perRow[r] >= 2 || perCol[c] >= 2) continue;
    cells.add((r, c));
    perRow[r]++;
    perCol[c]++;
  }
  return cells.toList();
}
