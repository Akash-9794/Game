import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'game/gem_grid_game.dart';
import 'ui/game_over_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only (Android + iOS). Web browsers ignore this.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(GemGridApp(game: GemGridGame()));
}

class GemGridApp extends StatelessWidget {
  const GemGridApp({super.key, required this.game});

  final GemGridGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gem Grid',
      debugShowCheckedModeBanner: false,
      home: GameWidget<GemGridGame>(
        game: game,
        overlayBuilderMap: {
          GemGridGame.gameOverOverlay: (context, game) =>
              GameOverOverlay(game: game),
        },
      ),
    );
  }
}
