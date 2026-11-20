// Pure Dart game logic — no Flutter or Flame imports allowed in lib/logic/.

import 'levels.dart';

/// Which Adventure levels are unlocked and how many stars each earned.
class AdventureProgress {
  AdventureProgress([Map<int, int>? stars]) : _stars = {...?stars};

  final Map<int, int> _stars;

  int starsFor(int level) => _stars[level] ?? 0;

  bool isCompleted(int level) => starsFor(level) > 0;

  /// Level 1 is always open; every other level opens when the one before
  /// it has been completed.
  bool isUnlocked(int level) =>
      level >= 1 && level <= levelCount && (level == 1 || isCompleted(level - 1));

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get maxStars => levelCount * 3;

  /// The first unlocked level not yet completed (or the last level).
  int get nextLevel {
    for (var n = 1; n <= levelCount; n++) {
      if (!isCompleted(n)) return n;
    }
    return levelCount;
  }

  /// Records a result, keeping the best star count.
  void record(int level, int stars) {
    if (stars > starsFor(level)) _stars[level] = stars.clamp(0, 3);
  }

  /// Saves as strings like "3:2" (level 3, 2 stars).
  List<String> encode() => [for (final e in _stars.entries) '${e.key}:${e.value}'];

  static AdventureProgress decode(List<String> data) {
    final stars = <int, int>{};
    for (final item in data) {
      final parts = item.split(':');
      if (parts.length != 2) continue;
      final level = int.tryParse(parts[0]), count = int.tryParse(parts[1]);
      if (level != null && count != null && level >= 1 && level <= levelCount) {
        stars[level] = count.clamp(0, 3);
      }
    }
    return AdventureProgress(stars);
  }
}
