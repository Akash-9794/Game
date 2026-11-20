// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

/// A block shape: a list of (row, col) cells relative to its top-left corner.
class Shape {
  final List<(int, int)> cells;
  const Shape(this.cells);

  /// Builds a shape from a picture like ['XX', 'X.'] ('X' = block).
  factory Shape.fromPattern(List<String> rows) {
    final cells = <(int, int)>[];
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        if (rows[r][c] == 'X') cells.add((r, c));
      }
    }
    return Shape(cells);
  }

  int get rows => cells.map((e) => e.$1).reduce((a, b) => a > b ? a : b) + 1;
  int get cols => cells.map((e) => e.$2).reduce((a, b) => a > b ? a : b) + 1;
}

/// Every shape the game can deal.
final List<Shape> allShapes = [
  // Singles and lines
  Shape.fromPattern(['X']),
  Shape.fromPattern(['XX']),
  Shape.fromPattern(['X', 'X']),
  Shape.fromPattern(['XXX']),
  Shape.fromPattern(['X', 'X', 'X']),
  Shape.fromPattern(['XXXX']),
  Shape.fromPattern(['X', 'X', 'X', 'X']),
  Shape.fromPattern(['XXXXX']),
  Shape.fromPattern(['X', 'X', 'X', 'X', 'X']),
  // Squares
  Shape.fromPattern(['XX', 'XX']),
  Shape.fromPattern(['XXX', 'XXX', 'XXX']),
  // Small corners
  Shape.fromPattern(['XX', 'X.']),
  Shape.fromPattern(['XX', '.X']),
  Shape.fromPattern(['X.', 'XX']),
  Shape.fromPattern(['.X', 'XX']),
  // Big corners
  Shape.fromPattern(['XXX', 'X..', 'X..']),
  Shape.fromPattern(['XXX', '..X', '..X']),
  Shape.fromPattern(['X..', 'X..', 'XXX']),
  Shape.fromPattern(['..X', '..X', 'XXX']),
  // L shapes
  Shape.fromPattern(['X.', 'X.', 'XX']),
  Shape.fromPattern(['.X', '.X', 'XX']),
  Shape.fromPattern(['XXX', 'X..']),
  Shape.fromPattern(['XXX', '..X']),
  // T shapes
  Shape.fromPattern(['XXX', '.X.']),
  Shape.fromPattern(['.X.', 'XXX']),
  Shape.fromPattern(['X.', 'XX', 'X.']),
  Shape.fromPattern(['.X', 'XX', '.X']),
  // S / Z shapes
  Shape.fromPattern(['XX.', '.XX']),
  Shape.fromPattern(['.XX', 'XX.']),
  Shape.fromPattern(['X.', 'XX', '.X']),
  Shape.fromPattern(['.X', 'XX', 'X.']),
];
