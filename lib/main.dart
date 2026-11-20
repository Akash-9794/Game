import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'services/game_storage.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only (Android + iOS). Web browsers ignore this.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final storage = await GameStorage.load();
  runApp(GemGridApp(storage: storage));
}
