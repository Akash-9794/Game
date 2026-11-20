import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../game/gem_grid_game.dart';
import '../game/gem_painter.dart';
import '../logic/adventure_game.dart';
import '../logic/classic_game.dart';
import '../services/game_storage.dart';
import 'widgets.dart';

enum _Panel { none, intro, paused, gameOver, levelWon, levelLost }

/// The play screen for both modes: Flutter score bar on top, the Flame
/// board and tray below, and pop-up panels (pause, results) over both.
class GameScreen extends StatefulWidget {
  const GameScreen.classic({super.key, required this.storage}) : level = null;

  const GameScreen.adventure({super.key, required this.storage, required Level this.level});

  final GameStorage storage;

  /// The Adventure level, or null for Classic.
  final Level? level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final TrayGame _logic;
  late final GemGridGame _game;
  _Panel _panel = _Panel.none;
  bool _newBest = false;
  Timer? _endTimer;

  bool get _isAdventure => widget.level != null;
  AdventureGame get _adventure => _logic as AdventureGame;
  GameStorage get _storage => widget.storage;

  @override
  void initState() {
    super.initState();
    _logic = _isAdventure ? AdventureGame(widget.level!) : ClassicGame();
    _game = GemGridGame(logic: _logic, onMove: _onMove);
    if (_isAdventure) _panel = _Panel.intro;
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    super.dispose();
  }

  void _onMove(PlaceResult result) {
    if (_storage.haptics) {
      if (result.clearedLines > 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (!_isAdventure && _storage.submitScore(_logic.score)) _newBest = true;
    setState(() {});

    if (_logic.isOver) {
      if (_isAdventure && _adventure.status == LevelStatus.won) {
        _storage.recordLevel(widget.level!.number, _adventure.stars);
      }
      // Let the last clear animation play before showing the result.
      _endTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _panel = !_isAdventure
              ? _Panel.gameOver
              : _adventure.status == LevelStatus.won
                  ? _Panel.levelWon
                  : _Panel.levelLost;
        });
      });
    }
  }

  void _pause() {
    if (_panel != _Panel.none || _logic.isOver) return;
    _game.pauseEngine();
    setState(() => _panel = _Panel.paused);
  }

  void _resume() {
    _game.resumeEngine();
    setState(() => _panel = _Panel.none);
  }

  void _restart() {
    _endTimer?.cancel();
    final logic = _logic;
    if (logic is ClassicGame) {
      logic.restart();
    } else if (logic is AdventureGame) {
      logic.restart();
    }
    _newBest = false;
    _game.refresh();
    _game.resumeEngine();
    setState(() => _panel = _Panel.none);
  }

  void _exit() => Navigator.of(context).pop();

  void _nextLevel() {
    final next = widget.level!.number; // levels are 1-based, list is 0-based
    if (next >= levels.length) return _exit();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => GameScreen.adventure(storage: _storage, level: levels[next])));
  }

  /// Android back button / browser back: pause instead of quitting.
  void _onBack() {
    switch (_panel) {
      case _Panel.none:
        if (_logic.isOver) return _exit();
        _pause();
      case _Panel.paused:
        _resume();
      case _Panel.intro:
      case _Panel.gameOver:
      case _Panel.levelWon:
      case _Panel.levelLost:
        _exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  PhoneWidth(child: _isAdventure ? _adventureBar() : _classicBar()),
                  Expanded(child: GameWidget(game: _game)),
                ],
              ),
              if (_panel != _Panel.none) Positioned.fill(child: _buildPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- top bars

  Widget _pauseButton() => IconButton(
        tooltip: 'Pause',
        onPressed: _pause,
        icon: const Icon(Icons.pause_rounded, size: 30),
        color: GemPalette.text,
        style: IconButton.styleFrom(backgroundColor: GemPalette.panel),
      );

  Widget _classicBar() {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _pauseButton(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('SCORE',
                      style: TextStyle(
                          color: GemPalette.subtleText,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  Text('${_logic.score}',
                      key: const Key('score'),
                      style: const TextStyle(
                          color: GemPalette.text,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                ],
              ),
            ),
            SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: GemPalette.gold, size: 22),
                  Text('${_storage.bestScore}',
                      style: const TextStyle(
                          color: GemPalette.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adventureBar() {
    final level = widget.level!;
    final a = _adventure;
    final lowMoves = a.movesLeft <= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              _pauseButton(),
              Expanded(
                child: Text('Level ${level.number}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: GemPalette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lowMoves ? GemPalette.gems[0] : GemPalette.panel,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Text('${a.movesLeft}',
                      key: const Key('moves'),
                      style: const TextStyle(
                          color: GemPalette.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  const Text('moves',
                      style: TextStyle(color: GemPalette.text, fontSize: 11)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (level.hasScoreGoal)
                Expanded(child: _scoreGoal(a.score, level.targetScore)),
              if (level.hasScoreGoal && level.hasTargetGoal) const SizedBox(width: 10),
              if (level.hasTargetGoal)
                _targetGoal(a.targetsLeft, level.targets.length,
                    expand: !level.hasScoreGoal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreGoal(int score, int target) {
    final done = score >= target;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: GemPalette.panel, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(done ? Icons.check_circle_rounded : Icons.star_rounded,
            color: done ? GemPalette.gems[2] : GemPalette.gold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score / target).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: GemPalette.emptyCell,
              color: done ? GemPalette.gems[2] : GemPalette.gold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$score / $target',
            style: const TextStyle(
                color: GemPalette.text, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _targetGoal(int left, int total, {required bool expand}) {
    final done = left == 0;
    final child = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: GemPalette.panel, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          done
              ? Icon(Icons.check_circle_rounded, color: GemPalette.gems[2], size: 22)
              : const GemBlock(gem: 4, size: 22, target: true),
          const SizedBox(width: 8),
          Text(done ? 'All cleared' : '$left left',
              style: const TextStyle(
                  color: GemPalette.text, fontWeight: FontWeight.bold)),
        ],
      ),
    );
    return expand ? Expanded(child: child) : child;
  }

  // ------------------------------------------------------------------ panels

  Widget _buildPanel() {
    final content = switch (_panel) {
      _Panel.intro => _introPanel(),
      _Panel.paused => _pausedPanel(),
      _Panel.gameOver => _gameOverPanel(),
      _Panel.levelWon => _levelWonPanel(),
      _Panel.levelLost => _levelLostPanel(),
      _Panel.none => const SizedBox.shrink(),
    };
    return Material(
      color: const Color(0xD9000000),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: GemPalette.panel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  static const _titleStyle = TextStyle(
      color: GemPalette.text, fontSize: 26, fontWeight: FontWeight.w900);
  static const _subStyle = TextStyle(
      color: GemPalette.subtleText, fontSize: 15, fontWeight: FontWeight.w600);

  Widget _column(List<Widget> children) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );

  Widget _introPanel() {
    final level = widget.level!;
    return _column([
      Text('Level ${level.number}', textAlign: TextAlign.center, style: _titleStyle),
      const SizedBox(height: 4),
      const Text('Goals', textAlign: TextAlign.center, style: _subStyle),
      const SizedBox(height: 16),
      if (level.hasScoreGoal)
        _goalLine(const Icon(Icons.star_rounded, color: GemPalette.gold, size: 28),
            'Reach ${level.targetScore} points'),
      if (level.hasTargetGoal)
        _goalLine(const GemBlock(gem: 4, size: 26, target: true),
            'Clear ${level.targets.length} diamond gems'),
      _goalLine(const Icon(Icons.touch_app_rounded, color: GemPalette.text, size: 26),
          'Within ${level.moves} moves'),
      const SizedBox(height: 20),
      PanelButton(label: 'Start', icon: Icons.play_arrow_rounded, onPressed: _resume),
      const SizedBox(height: 10),
      PanelButton(label: 'Back to levels', primary: false, onPressed: _exit),
    ]);
  }

  Widget _goalLine(Widget icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 36, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: GemPalette.text, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ]),
      );

  Widget _pausedPanel() => _column([
        const Text('Paused', textAlign: TextAlign.center, style: _titleStyle),
        const SizedBox(height: 24),
        PanelButton(label: 'Resume', icon: Icons.play_arrow_rounded, onPressed: _resume),
        const SizedBox(height: 10),
        PanelButton(
            label: 'Restart',
            icon: Icons.refresh_rounded,
            primary: false,
            onPressed: _restart),
        const SizedBox(height: 10),
        PanelButton(
            label: _isAdventure ? 'Quit to levels' : 'Quit to menu',
            icon: Icons.home_rounded,
            primary: false,
            onPressed: _exit),
      ]);

  Widget _gameOverPanel() => _column([
        const Text('No more moves', textAlign: TextAlign.center, style: _subStyle),
        const SizedBox(height: 8),
        Text('${_logic.score}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: GemPalette.text, fontSize: 60, fontWeight: FontWeight.w900)),
        Text(
          _newBest ? 'New best score!' : 'Best: ${_storage.bestScore}',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: GemPalette.gold, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        PanelButton(label: 'Play again', icon: Icons.refresh_rounded, onPressed: _restart),
        const SizedBox(height: 10),
        PanelButton(
            label: 'Menu', icon: Icons.home_rounded, primary: false, onPressed: _exit),
      ]);

  Widget _levelWonPanel() {
    final level = widget.level!;
    final isLast = level.number >= levels.length;
    return _column([
      Text('Level ${level.number}', textAlign: TextAlign.center, style: _subStyle),
      const Text('Complete!', textAlign: TextAlign.center, style: _titleStyle),
      const SizedBox(height: 12),
      Center(child: StarRow(count: _adventure.stars, size: 52)),
      const SizedBox(height: 8),
      Text('Score ${_logic.score}  ·  ${_adventure.movesLeft} moves left',
          textAlign: TextAlign.center, style: _subStyle),
      if (isLast) ...[
        const SizedBox(height: 12),
        const Text('You finished every level!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: GemPalette.gold, fontSize: 17, fontWeight: FontWeight.bold)),
      ],
      const SizedBox(height: 24),
      if (!isLast) ...[
        PanelButton(
            label: 'Next level', icon: Icons.arrow_forward_rounded, onPressed: _nextLevel),
        const SizedBox(height: 10),
      ],
      PanelButton(
          label: 'Replay', icon: Icons.refresh_rounded, primary: isLast, onPressed: _restart),
      const SizedBox(height: 10),
      PanelButton(
          label: 'Levels', icon: Icons.grid_view_rounded, primary: false, onPressed: _exit),
    ]);
  }

  Widget _levelLostPanel() {
    final reason = _adventure.lossReason == LossReason.outOfMoves
        ? 'Out of moves'
        : 'No space for your pieces';
    final level = widget.level!;
    final missing = <String>[
      if (_logic.score < level.targetScore)
        '${level.targetScore - _logic.score} more points',
      if (_adventure.targetsLeft > 0)
        '${_adventure.targetsLeft} diamond gem${_adventure.targetsLeft == 1 ? '' : 's'}',
    ];
    return _column([
      Text('Level ${level.number}', textAlign: TextAlign.center, style: _subStyle),
      Text(reason, textAlign: TextAlign.center, style: _titleStyle),
      const SizedBox(height: 12),
      if (missing.isNotEmpty)
        Text('So close! You still needed ${missing.join(' and ')}.',
            textAlign: TextAlign.center, style: _subStyle),
      const SizedBox(height: 24),
      PanelButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: _restart),
      const SizedBox(height: 10),
      PanelButton(
          label: 'Levels', icon: Icons.grid_view_rounded, primary: false, onPressed: _exit),
    ]);
  }
}
