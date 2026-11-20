import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/adventure_progress.dart';
import 'package:gem_grid/logic/levels.dart';

void main() {
  test('only level 1 is unlocked at first', () {
    final p = AdventureProgress();
    expect(p.isUnlocked(1), isTrue);
    expect(p.isUnlocked(2), isFalse);
    expect(p.nextLevel, 1);
    expect(p.totalStars, 0);
  });

  test('completing a level unlocks the next one', () {
    final p = AdventureProgress()..record(1, 2);
    expect(p.isUnlocked(2), isTrue);
    expect(p.isUnlocked(3), isFalse);
    expect(p.nextLevel, 2);
  });

  test('record keeps the best stars', () {
    final p = AdventureProgress()
      ..record(1, 3)
      ..record(1, 1);
    expect(p.starsFor(1), 3);
    expect(p.totalStars, 3);
  });

  test('losing (0 stars) does not unlock anything', () {
    final p = AdventureProgress()..record(1, 0);
    expect(p.isUnlocked(2), isFalse);
  });

  test('encode / decode round trip, ignoring junk', () {
    final p = AdventureProgress()
      ..record(1, 3)
      ..record(2, 1);
    final back = AdventureProgress.decode([...p.encode(), 'junk', '99:3', '5:x']);
    expect(back.starsFor(1), 3);
    expect(back.starsFor(2), 1);
    expect(back.totalStars, 4);
    expect(back.maxStars, levelCount * 3);
  });
}
