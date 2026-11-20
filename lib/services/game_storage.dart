import 'package:shared_preferences/shared_preferences.dart';

import '../logic/adventure_progress.dart';

/// Saves everything the player keeps between sessions: best Classic score,
/// Adventure stars and settings. Uses the phone's storage (or the browser's
/// on web). If storage is unavailable, values live in memory only.
class GameStorage {
  GameStorage._(this._prefs, this.bestScore, this.progress, this.haptics, this.sound);

  static const _bestKey = 'classic_best_score';
  static const _progressKey = 'adventure_progress';
  static const _hapticsKey = 'haptics_enabled';
  static const _soundKey = 'sound_enabled';

  final SharedPreferences? _prefs;

  int bestScore;
  AdventureProgress progress;
  bool haptics;
  bool sound;

  static Future<GameStorage> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return GameStorage._(
        prefs,
        prefs.getInt(_bestKey) ?? 0,
        AdventureProgress.decode(prefs.getStringList(_progressKey) ?? const []),
        prefs.getBool(_hapticsKey) ?? true,
        prefs.getBool(_soundKey) ?? true,
      );
    } catch (_) {
      return GameStorage.memory();
    }
  }

  /// Storage that is never saved (used for tests or private browsing).
  factory GameStorage.memory() =>
      GameStorage._(null, 0, AdventureProgress(), true, true);

  Future<void> _write(Future<bool> Function(SharedPreferences p) op) async {
    final p = _prefs;
    if (p == null) return;
    try {
      await op(p);
    } catch (_) {
      // Losing a save is better than crashing the game.
    }
  }

  /// Updates the best score if [score] beats it. Returns true if it did.
  bool submitScore(int score) {
    if (score <= bestScore) return false;
    bestScore = score;
    _write((p) => p.setInt(_bestKey, score));
    return true;
  }

  void recordLevel(int level, int stars) {
    progress.record(level, stars);
    _write((p) => p.setStringList(_progressKey, progress.encode()));
  }

  void setHaptics(bool on) {
    haptics = on;
    _write((p) => p.setBool(_hapticsKey, on));
  }

  void setSound(bool on) {
    sound = on;
    _write((p) => p.setBool(_soundKey, on));
  }

  /// Clears best score and Adventure progress (settings are kept).
  void resetProgress() {
    bestScore = 0;
    progress = AdventureProgress();
    _write((p) => p.remove(_bestKey));
    _write((p) => p.remove(_progressKey));
  }
}
