import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import '../services/game_storage.dart';
import 'home_screen.dart';

class GemGridApp extends StatelessWidget {
  const GemGridApp({super.key, required this.storage});

  final GameStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gem Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GemPalette.background,
        colorScheme: ColorScheme.dark(
          primary: GemPalette.gems[3],
          secondary: GemPalette.gold,
          surface: GemPalette.panel,
        ),
      ),
      home: HomeScreen(storage: storage),
    );
  }
}
