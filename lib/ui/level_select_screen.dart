import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import '../logic/levels.dart';
import '../services/game_storage.dart';
import 'game_screen.dart';
import 'widgets.dart';

/// Grid of the 30 Adventure levels with stars and locks.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.storage});

  final GameStorage storage;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _play(Level level) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GameScreen.adventure(
            storage: widget.storage, level: level)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.storage.progress;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Adventure',
                trailing: Row(children: [
                  const Icon(Icons.star_rounded, color: GemPalette.gold),
                  const SizedBox(width: 4),
                  Text('${progress.totalStars} / ${progress.maxStars}',
                      style: const TextStyle(
                          color: GemPalette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: levels.length,
                  itemBuilder: (context, i) {
                    final level = levels[i];
                    final unlocked = progress.isUnlocked(level.number);
                    return _LevelTile(
                      level: level,
                      unlocked: unlocked,
                      stars: progress.starsFor(level.number),
                      isNext: unlocked && level.number == progress.nextLevel,
                      onTap: unlocked
                          ? () => _play(level)
                          : () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              content: Text(
                                  'Finish level ${level.number - 1} to unlock level ${level.number}.'),
                              duration: const Duration(seconds: 2),
                            )),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.isNext,
    required this.onTap,
  });

  final Level level;
  final bool unlocked;
  final int stars;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? GemPalette.panel : GemPalette.boardBack;
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNext
            ? const BorderSide(color: GemPalette.gold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (unlocked) ...[
              Text('${level.number}',
                  style: const TextStyle(
                      color: GemPalette.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              StarRow(count: stars, size: 14),
            ] else
              const Icon(Icons.lock_rounded,
                  color: GemPalette.subtleText, size: 22),
          ],
        ),
      ),
    );
  }
}
