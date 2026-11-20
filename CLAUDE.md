# Gem Grid — notes for Claude

Gem Grid is a mobile block-puzzle game built with **Flutter** and the **Flame** game engine.
The Flutter project lives at the repository root (package name `gem_grid`). Portrait only.

## The game
- **Board:** 9x9 grid of cells.
- **Turns:** the player is offered **3 shapes per turn**. They drag each shape onto the board
  in any order. When all 3 are placed, 3 new shapes are dealt.
- **Clearing:** any **full row or full column** is cleared (both at once if both are full).
- **Scoring:** points for each cell placed, plus points per cleared line.
  Clearing several lines at once and clearing on **consecutive placements (combo)**
  multiply the reward. A placement that clears nothing resets the combo.
- **Game over:** when none of the remaining shapes fits anywhere on the board.
- **Modes:**
  - **Classic** — endless play, chase the high score.
  - **Adventure** — level-based play with goals (e.g. reach a score, clear target gems).
- **Monetization (later):** Google **AdMob** ads (banner, interstitial between games,
  rewarded ads e.g. for a continue). Not added yet — keep ad code isolated in its own
  service class so the game works without it (and on web, where AdMob is unavailable).

## Architecture rules
- **Game logic is pure Dart** in `lib/logic/`. Files there must NOT import
  `package:flutter`, `package:flame`, or `dart:ui`. This keeps rules fast to unit-test.
- **Rendering and input** live in `lib/game/` (Flame components). They read state from
  the logic classes and call into them; they never contain game rules.
- **Flutter UI** (menus, mode select, settings, overlays) lives in `lib/ui/` when added.
- Every logic class gets **unit tests** in `test/logic/`. Add or update tests with every
  rule change.

## Layout
```
lib/main.dart                     App entry: locks portrait, shows the Flame GameWidget
lib/logic/shape.dart              Shape + list of all dealable shapes (pure Dart)
lib/logic/board.dart              9x9 board, placement, line clears, combo scoring (pure Dart)
lib/logic/classic_game.dart       Classic mode: tray of 3 pieces, dealing, game over (pure Dart)
lib/game/gem_grid_game.dart       FlameGame: layout, HUD, connects input to ClassicGame
lib/game/board_component.dart     Draws the board, drag preview and clear animation
lib/game/piece_component.dart     Draggable tray piece
lib/game/floating_text.dart       "+40" / "Combo x2" popups
lib/game/gem_painter.dart         Gem colours and block drawing
lib/ui/game_over_overlay.dart     Flutter "No more moves / Play again" screen
lib/services/best_score_store.dart  Saves best score (shared_preferences)
test/logic/                       Unit tests for all logic classes
.github/workflows/build.yml       CI: test, Android APK, web deploy to GitHub Pages
```

## Status
- Done: Classic mode (drag & drop, clears, combo scoring, game over, best score).
- Next: main menu + mode select, Adventure mode, sounds, AdMob.

## Commands
- `flutter test` — run all tests (must pass before pushing)
- `flutter analyze` — lint (keep at "No issues found")
- `flutter build apk --debug` — Android debug APK
- `flutter build web --release --base-href /<repo-name>/` — web build for GitHub Pages

## Environment
The owner has no local setup. Everything is built and verified in CI
(GitHub Actions, see `.github/workflows/build.yml`). Pushes to `main` run tests,
upload a debug APK artifact, and deploy the web build to GitHub Pages.
