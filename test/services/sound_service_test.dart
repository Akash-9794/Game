import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gem_grid/services/sound_service.dart';

void main() {
  test('every sound effect has a file in assets/audio', () {
    for (final sfx in Sfx.values) {
      expect(File('assets/audio/${sfx.file}').existsSync(), isTrue,
          reason: '${sfx.file} is missing');
    }
  });

  test('silent service never throws, even before preload', () {
    final s = SoundService.silent();
    for (final sfx in Sfx.values) {
      s.play(sfx);
    }
  });

  test('enabled service without loaded sounds is a no-op', () {
    final s = SoundService(enabled: () => true);
    s.play(Sfx.place); // nothing preloaded: must not throw
  });
}
