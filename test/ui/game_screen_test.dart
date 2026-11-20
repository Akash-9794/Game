import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/levels.dart';
import 'package:gem_grid/services/game_storage.dart';
import 'package:gem_grid/ui/game_screen.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  // Let Flame load and lay out.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Drags the piece in tray slot [slot] up onto the board.
Future<void> dragPieceToBoard(WidgetTester tester, int slot) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final from = Offset(size.width * (slot * 2 + 1) / 6, size.height * 0.80);
  final gesture = await tester.startGesture(from);
  // The piece floats above the finger, so stop the finger in the lower part
  // of the board: any shape (up to 5 tall) then lands fully on the board.
  final to = Offset(size.width / 2, size.height * 0.62);
  for (var i = 1; i <= 10; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('classic: pause, resume and quit', (tester) async {
    await pumpScreen(tester, GameScreen.classic(storage: GameStorage.memory()));
    expect(find.text('SCORE'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('Paused'), findsNothing);
  });

  testWidgets('classic: dragging a piece onto the board scores points',
      (tester) async {
    final storage = GameStorage.memory();
    await pumpScreen(tester, GameScreen.classic(storage: storage));
    await dragPieceToBoard(tester, 1);
    final score = tester.widget<Text>(find.byKey(const Key('score')));
    expect(int.parse(score.data!), greaterThan(0));
    expect(storage.bestScore, greaterThan(0));
  });

  testWidgets('adventure: intro, win, stars saved, next level unlocked',
      (tester) async {
    final storage = GameStorage.memory();
    const easy = Level(number: 1, targetScore: 1, targets: [], moves: 5);
    await pumpScreen(tester, GameScreen.adventure(storage: storage, level: easy));

    expect(find.text('Reach 1 points'), findsOneWidget);
    expect(find.text('Within 5 moves'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pump();

    await dragPieceToBoard(tester, 1);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Complete!'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
    expect(storage.progress.starsFor(1), 3);
    expect(storage.progress.isUnlocked(2), isTrue);
  });

  testWidgets('adventure: running out of moves shows Try again',
      (tester) async {
    final storage = GameStorage.memory();
    const hard = Level(number: 1, targetScore: 999, targets: [], moves: 1);
    await pumpScreen(tester, GameScreen.adventure(storage: storage, level: hard));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await dragPieceToBoard(tester, 1);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Out of moves'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(storage.progress.isUnlocked(2), isFalse);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    final moves = tester.widget<Text>(find.byKey(const Key('moves')));
    expect(moves.data, '1');
  });
}
