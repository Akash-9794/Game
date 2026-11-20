import 'package:material_ui/material_ui.dart';

import '../game/gem_grid_game.dart';
import '../game/gem_painter.dart';

/// Flutter screen shown on top of the game when no piece fits.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final GemGridGame game;

  @override
  Widget build(BuildContext context) {
    final isBest = game.logic.score > 0 && game.logic.score >= game.bestScore;
    return Material(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: GemPalette.boardBack,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No more moves',
                style: TextStyle(
                    color: GemPalette.subtleText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                '${game.logic.score}',
                style: const TextStyle(
                    color: GemPalette.text,
                    fontSize: 56,
                    fontWeight: FontWeight.w900),
              ),
              Text(
                isBest ? 'New best score!' : 'Best: ${game.bestScore}',
                style: TextStyle(
                    color: GemPalette.gems[1],
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: GemPalette.gems[3],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: game.restart,
                child: const Text('Play again',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
