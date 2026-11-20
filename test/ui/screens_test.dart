import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/logic/levels.dart';
import 'package:gem_grid/services/game_storage.dart';
import 'package:gem_grid/ui/app.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpApp(WidgetTester tester, GameStorage storage) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GemGridApp(storage: storage));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows both modes, best score and stars', (tester) async {
    final storage = GameStorage.memory()..submitScore(123);
    await pumpApp(tester, storage);
    expect(find.text('Gem Grid'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Best score: 123'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
    expect(find.textContaining('★ 0 / 90'), findsOneWidget);
  });

  testWidgets('settings: toggle vibration and reset progress', (tester) async {
    final storage = GameStorage.memory()..submitScore(50);
    await pumpApp(tester, storage);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Vibration'));
    await tester.pumpAndSettle();
    expect(storage.haptics, isFalse);
    expect(storage.sound, isTrue);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Sound effects'));
    await tester.pumpAndSettle();
    expect(storage.sound, isFalse);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(storage.bestScore, 0);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Best score: 0'), findsOneWidget);
  });

  testWidgets('how to play opens and goes back', (tester) async {
    await pumpApp(tester, GameStorage.memory());
    await tester.tap(find.text('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('Fill rows and columns'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Classic'), findsOneWidget);
  });

  testWidgets('level select: level 1 open, level 2 locked until level 1 won',
      (tester) async {
    final storage = GameStorage.memory();
    await pumpApp(tester, storage);
    await tester.tap(find.text('Adventure'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(levelCount - 1));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();
    expect(find.textContaining('Finish level 1'), findsOneWidget);

    storage.recordLevel(1, 2);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adventure'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(levelCount - 2));
  });
}
