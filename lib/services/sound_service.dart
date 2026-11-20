import 'package:flame_audio/flame_audio.dart';

/// The game's sound effects (files in assets/audio/, made by
/// tools/make_sounds.py).
enum Sfx {
  place('place.wav'),
  tap('tap.wav'),
  clear('clear.wav'),
  combo('combo.wav'),
  gameOver('game_over.wav'),
  win('win.wav'),
  lose('lose.wav');

  const Sfx(this.file);
  final String file;
}

/// Plays sound effects. Sound must never crash the game, so every audio
/// call is guarded. Until [instance] is replaced in main(), it stays silent
/// (that is what widget tests use).
class SoundService {
  SoundService({required this.enabled});

  SoundService.silent() : enabled = (() => false);

  /// The app-wide sound player.
  static SoundService instance = SoundService.silent();

  /// Read before every sound, so the Settings switch applies instantly.
  final bool Function() enabled;
  final Map<Sfx, AudioPool> _pools = {};

  /// Loads every sound so the first play has no delay.
  Future<void> preload() async {
    for (final sfx in Sfx.values) {
      try {
        // A pool reuses a few players instead of creating one per play.
        _pools[sfx] = await FlameAudio.createPool(sfx.file, maxPlayers: 3);
      } catch (_) {
        // Audio unavailable on this device/browser: stay silent.
      }
    }
  }

  void play(Sfx sfx, {double volume = 1}) {
    if (!enabled()) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    try {
      pool.start(volume: volume).then<void>((_) {}, onError: (Object _) {});
    } catch (_) {
      // Ignore: a missed sound is fine.
    }
  }
}
