// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'tray_game.dart';

export 'tray_game.dart';

/// Classic mode: endless play, chase the high score.
/// Game over when none of the remaining pieces fits.
class ClassicGame extends TrayGame {
  ClassicGame({super.random, super.dealer}) {
    start();
  }

  @override
  bool get isOver => noMovesLeft;

  bool get isGameOver => isOver;

  void restart() => start();
}
