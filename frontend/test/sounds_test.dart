import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/sounds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Silenciar persiste y bloquea la reproducción', () async {
    SharedPreferences.setMockInitialValues({});
    final played = <UiSound>[];
    final sounds = AppSounds(playback: (sound) async => played.add(sound));
    await sounds.init();
    await sounds.play(UiSound.add);
    expect(played, [UiSound.add]);
    await sounds.setEnabled(false);
    await sounds.play(UiSound.tap);
    expect(played, [UiSound.add]);
    final restored = AppSounds(playback: (_) async {});
    await restored.init();
    expect(restored.enabled, isFalse);
    sounds.dispose();
    restored.dispose();
  });
  test(
    'La confirmación se reproduce aunque otro sonido esté iniciando',
    () async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<void>();
      final played = <UiSound>[];
      final sounds = AppSounds(
        playback: (sound) async {
          played.add(sound);
          if (sound == UiSound.tap) await pending.future;
        },
      );
      await sounds.init();
      final first = sounds.play(UiSound.tap);
      await sounds.play(UiSound.success);
      pending.complete();
      await first;
      expect(played, [UiSound.tap, UiSound.success]);
      sounds.dispose();
    },
  );
}
