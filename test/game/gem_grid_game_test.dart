import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/game/gem_grid_game.dart';
import 'package:gem_grid/logic/classic_game.dart';

void main() {
  test('game uses a dark background', () {
    final c = GemGridGame(logic: ClassicGame()).backgroundColor();
    expect(c.computeLuminance(), lessThan(0.1));
  });
}
