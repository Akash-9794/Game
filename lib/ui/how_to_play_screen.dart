import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import 'widgets.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              const ScreenHeader(title: 'How to play'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _Tip(
                      icon: Row(mainAxisSize: MainAxisSize.min, children: [
                        GemBlock(gem: 3, size: 18),
                        GemBlock(gem: 3, size: 18),
                      ]),
                      title: 'Drag pieces onto the board',
                      text: 'You get 3 pieces at a time. Place all 3 to get 3 new ones. '
                          'Pieces can\'t be rotated.',
                    ),
                    _Tip(
                      icon: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 4; i++) GemBlock(gem: 2, size: 14),
                      ]),
                      title: 'Fill rows and columns',
                      text: 'A full row or column disappears. Clearing several lines at '
                          'once scores much more.',
                    ),
                    const _Tip(
                      icon: Icon(Icons.local_fire_department_rounded,
                          color: GemPalette.gold, size: 32),
                      title: 'Build combos',
                      text: 'Clear lines on moves in a row to multiply your points. '
                          'A move that clears nothing ends the combo.',
                    ),
                    const _Tip(
                      icon: Icon(Icons.block_rounded,
                          color: GemPalette.subtleText, size: 32),
                      title: 'Keep space free',
                      text: 'The game ends when none of your pieces fits. Faded pieces '
                          'don\'t fit anywhere right now.',
                    ),
                    _Tip(
                      icon: GemBlock(gem: 4, size: 32, target: true),
                      title: 'Adventure',
                      text: 'Each level has goals: reach a score and/or clear every '
                          'diamond gem, within a limited number of moves. '
                          'Finish with moves to spare to earn up to 3 stars.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.title, required this.text});

  final Widget icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GemPalette.panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(width: 72, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: GemPalette.text,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(
                          color: GemPalette.subtleText, fontSize: 14, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );
}
