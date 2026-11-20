import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/shape.dart';

void main() {
  test('fromPattern reads blocks and size', () {
    final s = Shape.fromPattern(['XX.', '.XX']);
    expect(s.cells, [(0, 0), (0, 1), (1, 1), (1, 2)]);
    expect(s.rows, 2);
    expect(s.cols, 3);
  });

  test('every shape fits inside a 5x5 area and starts at row 0 / col 0', () {
    for (final s in allShapes) {
      expect(s.cells, isNotEmpty);
      expect(s.rows, lessThanOrEqualTo(5));
      expect(s.cols, lessThanOrEqualTo(5));
      expect(s.cells.any((c) => c.$1 == 0), isTrue);
      expect(s.cells.any((c) => c.$2 == 0), isTrue);
    }
  });
}
