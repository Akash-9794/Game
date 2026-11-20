import 'package:material_ui/material_ui.dart';

import '../game/gem_painter.dart';
import '../services/game_storage.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.storage});

  final GameStorage storage;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GemPalette.panel,
        title: const Text('Reset progress?'),
        content: const Text(
            'This deletes your best Classic score and all Adventure stars. '
            'It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: GemPalette.gems[0]),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(widget.storage.resetProgress);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.storage;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Settings'),
              const SizedBox(height: 8),
              _Card(children: [
                SwitchListTile(
                  title: const Text('Sound effects'),
                  value: s.sound,
                  activeThumbColor: GemPalette.gems[3],
                  onChanged: (v) => setState(() => s.setSound(v)),
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Buzz when you place pieces and clear lines'),
                  value: s.haptics,
                  activeThumbColor: GemPalette.gems[3],
                  onChanged: (v) => setState(() => s.setHaptics(v)),
                ),
              ]),
              _Card(children: [
                ListTile(
                  leading: Icon(Icons.restart_alt_rounded, color: GemPalette.gems[0]),
                  title: const Text('Reset progress'),
                  subtitle: const Text('Best score and Adventure stars'),
                  onTap: _confirmReset,
                ),
              ]),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Gem Grid · version 1.0.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GemPalette.subtleText)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: GemPalette.panel,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      );
}
