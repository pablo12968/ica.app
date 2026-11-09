import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UiSound { tap, add, success }

class AppSounds extends ChangeNotifier {
  AppSounds({this.playback});
  final Future<void> Function(UiSound)? playback;
  bool enabled = false;
  bool _busy = false;
  bool _disposed = false;
  UiSound? _pending;
  AudioPlayer? _player;
  SharedPreferences? _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      enabled = _prefs!.getBool('ica_sound') ?? true;
    } catch (_) {
      enabled = true;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    notifyListeners();
    try {
      await _prefs?.setBool('ica_sound', value);
      if (!value) await _player?.stop();
    } catch (_) {
      /* La preferencia de esta sesión sigue vigente. */
    }
  }

  Future<void> play(UiSound sound) async {
    if (!enabled || _disposed) return;
    if (_busy) {
      if (sound == UiSound.success) _pending = sound;
      return;
    }
    _busy = true;
    try {
      if (playback != null) {
        await playback!(sound);
      } else {
        final player = _player ??= AudioPlayer();
        await player.stop();
        if (enabled) {
          await player.play(
            AssetSource('sounds/${sound.name}.wav'),
            volume: .35,
          );
        }
      }
    } catch (_) {
      // Un dispositivo silenciado o un bloqueo de audio no interrumpen la compra.
    } finally {
      _busy = false;
      final pending = _pending;
      _pending = null;
      if (pending != null) unawaited(play(pending));
    }
  }

  VoidCallback action(VoidCallback callback, [UiSound sound = UiSound.tap]) =>
      () {
        unawaited(play(sound));
        callback();
      };

  @override
  void dispose() {
    _disposed = true;
    unawaited(_player?.dispose());
    super.dispose();
  }
}
