import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import '../services/sound_service.dart';

/// Plays the button tap sound, then runs [action].
void _tapThen(VoidCallback action) {
  SoundService.instance.play(Sfx.tap);
  action();
}

/// Small row of gems used as the game's logo.
class GemLogo extends StatelessWidget {
  const GemLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    const pattern = [
      [0, 1, 3],
      [5, -1, 2],
      [4, 6, -1],
    ];
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: CustomPaint(
        painter: _GemGridPainter(pattern, size),
      ),
    );
  }
}

class _GemGridPainter extends CustomPainter {
  _GemGridPainter(this.pattern, this.cell);

  final List<List<int>> pattern;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    for (var r = 0; r < pattern.length; r++) {
      for (var c = 0; c < pattern[r].length; c++) {
        final g = pattern[r][c];
        if (g < 0) continue;
        final gap = cell * 0.07;
        drawGem(
          canvas,
          Rect.fromLTWH(c * cell + gap, r * cell + gap, cell - 2 * gap,
              cell - 2 * gap),
          GemPalette.gem(g),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GemGridPainter old) => false;
}

/// A single gem block as a widget (used for icons in the UI).
class GemBlock extends StatelessWidget {
  const GemBlock({super.key, required this.gem, this.size = 20, this.target = false});

  final int gem;
  final double size;
  final bool target;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _BlockPainter(gem, target)),
      );
}

class _BlockPainter extends CustomPainter {
  _BlockPainter(this.gem, this.target);
  final int gem;
  final bool target;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    drawGem(canvas, rect, GemPalette.gem(gem));
    if (target) drawTargetMark(canvas, rect);
  }

  @override
  bool shouldRepaint(covariant _BlockPainter old) =>
      old.gem != gem || old.target != target;
}

/// Row of 3 stars, [count] of them filled.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.count, this.size = 16, this.max = 3});

  final int count;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < count ? GemPalette.gold : GemPalette.subtleText,
            ),
        ],
      );
}

/// Big rounded menu button with an icon, title and subtitle.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap == null ? null : () => _tapThen(onTap!),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width button used inside dialogs/overlays.
class PanelButton extends StatelessWidget {
  const PanelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: primary ? GemPalette.gems[3] : GemPalette.emptyCell,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    );
    return icon == null
        ? FilledButton(
            style: style, onPressed: () => _tapThen(onPressed), child: Text(label))
        : FilledButton.icon(
            style: style,
            onPressed: () => _tapThen(onPressed),
            icon: Icon(icon),
            label: Text(label));
  }
}

/// Simple top bar with a back button and a title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: GemPalette.text,
            onPressed: () => _tapThen(() => Navigator.of(context).maybePop()),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: GemPalette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Keeps content phone-width and centred on big screens.
class PhoneWidth extends StatelessWidget {
  const PhoneWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      );
}
