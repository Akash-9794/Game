import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import '../services/game_storage.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';
import 'widgets.dart';

/// First screen: pick Classic or Adventure.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.storage});

  final GameStorage storage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStorage get storage => widget.storage;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // Scores/stars may have changed.
  }

  @override
  Widget build(BuildContext context) {
    final progress = storage.progress;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const GemLogo(size: 30),
                const SizedBox(height: 16),
                const Text('Gem Grid',
                    style: TextStyle(
                        color: GemPalette.text,
                        fontSize: 44,
                        fontWeight: FontWeight.w900)),
                const Text('Block puzzle',
                    style: TextStyle(
                        color: GemPalette.subtleText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const Spacer(flex: 2),
                MenuButton(
                  title: 'Classic',
                  subtitle: 'Best score: ${storage.bestScore}',
                  icon: Icons.all_inclusive_rounded,
                  color: GemPalette.gems[3],
                  onTap: () => _open(GameScreen.classic(storage: storage)),
                ),
                const SizedBox(height: 14),
                MenuButton(
                  title: 'Adventure',
                  subtitle:
                      'Level ${progress.nextLevel}  ·  ★ ${progress.totalStars} / ${progress.maxStars}',
                  icon: Icons.map_rounded,
                  color: GemPalette.gems[4],
                  onTap: () => _open(LevelSelectScreen(storage: storage)),
                ),
                const Spacer(),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        SoundService.instance.play(Sfx.tap);
                        _open(const HowToPlayScreen());
                      },
                      icon: const Icon(Icons.help_outline_rounded),
                      label: const Text('How to play'),
                      style: TextButton.styleFrom(
                          foregroundColor: GemPalette.subtleText),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        SoundService.instance.play(Sfx.tap);
                        _open(SettingsScreen(storage: storage));
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Settings'),
                      style: TextButton.styleFrom(
                          foregroundColor: GemPalette.subtleText),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
