import 'package:shared_preferences/shared_preferences.dart';

/// Saves the best Classic score on the device (or in the browser on web).
class BestScoreStore {
  static const _key = 'classic_best_score';

  Future<int> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key) ?? 0;
    } catch (_) {
      return 0; // Storage unavailable (e.g. private browsing): start from 0.
    }
  }

  Future<void> save(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, score);
    } catch (_) {
      // Ignore: losing the best score is not worth crashing the game.
    }
  }
}
