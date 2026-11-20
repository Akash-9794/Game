// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'levels.dart';
import 'tray_game.dart';

export 'levels.dart';
export 'tray_game.dart';

enum LevelStatus { playing, won, lost }

/// Why a level was lost.
enum LossReason { outOfMoves, noSpace }

/// Adventure mode: one [Level] with goals and a move limit.
class AdventureGame extends TrayGame {
  AdventureGame(this.level, {super.random, super.dealer}) {
    start();
  }

  final Level level;
  late int movesLeft;
  LevelStatus status = LevelStatus.playing;
  LossReason? lossReason;

  int get targetsLeft => board.targetCount;
  int get movesUsed => level.moves - movesLeft;

  @override
  bool get isOver => status != LevelStatus.playing;

  @override
  Board createBoard() {
    final b = Board();
    for (var i = 0; i < level.targets.length; i++) {
      final (r, c) = level.targets[i];
      b.addTarget(r, c, i % gemColorCount);
    }
    return b;
  }

  @override
  void start() {
    movesLeft = level.moves;
    status = LevelStatus.playing;
    lossReason = null;
    super.start();
  }

  bool get goalsReached =>
      score >= level.targetScore && board.targetCount == 0;

  @override
  void afterPlace(PlaceResult result) {
    movesLeft--;
    if (goalsReached) {
      status = LevelStatus.won;
    } else if (movesLeft <= 0) {
      status = LevelStatus.lost;
      lossReason = LossReason.outOfMoves;
    } else if (noMovesLeft) {
      status = LevelStatus.lost;
      lossReason = LossReason.noSpace;
    }
  }

  /// 1-3 stars for a won level, based on how many moves were left.
  int get stars {
    if (status != LevelStatus.won) return 0;
    final left = movesLeft / level.moves;
    if (left >= 0.4) return 3;
    if (left >= 0.2) return 2;
    return 1;
  }

  void restart() => start();
}
