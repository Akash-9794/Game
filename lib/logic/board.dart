// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'shape.dart';

export 'shape.dart';

/// What happened after placing a shape.
class PlaceResult {
  final List<int> clearedRows;
  final List<int> clearedCols;
  final int pointsGained;
  final int combo;

  /// How many Adventure target gems were cleared by this placement.
  final int clearedTargets;

  const PlaceResult({
    required this.clearedRows,
    required this.clearedCols,
    required this.pointsGained,
    required this.combo,
    this.clearedTargets = 0,
  });

  int get clearedLines => clearedRows.length + clearedCols.length;
}

/// The 9x9 board. Each cell is empty (null) or holds a gem colour number.
class Board {
  static const int size = 9;

  final List<List<int?>> _cells =
      List.generate(size, (_) => List<int?>.filled(size, null));

  /// Cells holding Adventure target gems (must be cleared to win a level).
  final Set<(int, int)> _targets = {};

  int score = 0;

  /// How many placements in a row have cleared at least one line.
  int combo = 0;

  bool isFilled(int row, int col) => _cells[row][col] != null;

  /// The gem colour at a cell, or null if empty.
  int? gemAt(int row, int col) => _cells[row][col];

  bool isTarget(int row, int col) => _targets.contains((row, col));

  int get targetCount => _targets.length;

  /// Puts a target gem on an empty cell (used when an Adventure level starts).
  void addTarget(int row, int col, int gem) {
    if (_cells[row][col] != null) {
      throw ArgumentError('Cell ($row, $col) is not empty');
    }
    _cells[row][col] = gem;
    _targets.add((row, col));
  }

  bool canPlace(Shape shape, int row, int col) {
    for (final (r, c) in shape.cells) {
      final rr = row + r, cc = col + c;
      if (rr < 0 || rr >= size || cc < 0 || cc >= size) return false;
      if (_cells[rr][cc] != null) return false;
    }
    return true;
  }

  /// Rows and columns that would be full if [shape] were placed at
  /// ([row], [col]). Used to preview clears while dragging.
  (List<int>, List<int>) linesCompletedBy(Shape shape, int row, int col) {
    if (!canPlace(shape, row, col)) return (const [], const []);
    final added = {for (final (r, c) in shape.cells) (row + r, col + c)};
    bool filled(int r, int c) => _cells[r][c] != null || added.contains((r, c));
    return (
      [
        for (var r = 0; r < size; r++)
          if (List.generate(size, (c) => filled(r, c)).every((f) => f)) r,
      ],
      [
        for (var c = 0; c < size; c++)
          if (List.generate(size, (r) => filled(r, c)).every((f) => f)) c,
      ],
    );
  }

  /// Places [shape] with its top-left at ([row], [col]), clears full rows
  /// and columns, and updates score and combo.
  ///
  /// Scoring: 1 point per block placed, plus 10 × lines² for the lines
  /// cleared (1 line = 10, 2 = 40, 3 = 90 …), multiplied by the combo streak.
  PlaceResult place(Shape shape, int row, int col, {int gem = 0}) {
    if (!canPlace(shape, row, col)) {
      throw ArgumentError('Shape does not fit at ($row, $col)');
    }
    final (fullRows, fullCols) = linesCompletedBy(shape, row, col);
    for (final (r, c) in shape.cells) {
      _cells[row + r][col + c] = gem;
    }
    final targetsBefore = _targets.length;
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        _cells[r][c] = null;
        _targets.remove((r, c));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        _cells[r][c] = null;
        _targets.remove((r, c));
      }
    }

    final lines = fullRows.length + fullCols.length;
    combo = lines > 0 ? combo + 1 : 0;
    final points =
        shape.cells.length + (lines == 0 ? 0 : 10 * lines * lines * combo);
    score += points;
    return PlaceResult(
      clearedRows: fullRows,
      clearedCols: fullCols,
      pointsGained: points,
      combo: combo,
      clearedTargets: targetsBefore - _targets.length,
    );
  }

  /// True if [shape] fits anywhere on the board.
  bool fitsAnywhere(Shape shape) {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }
}
