import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [Sprint 15 F1] This phone's choices, as on the web (X56, Sprint 43 A1): the look (the device's by default, or night or
/// day) and the language (Arabic by default). Kept on the phone only.
class Settings {
  const Settings({
    this.theme = ThemeMode.system,
    this.language = 'ar',
    this.sounds = true,
    this.soundUi = 80,
    this.soundStadium = 80,
    this.touch = true,
  });

  final ThemeMode theme;
  final String language;

  /// [2026-11-06] The game's sounds (core/sounds.dart), on by default.
  final bool sounds;

  /// [Sprint 63 G13] The sound's levels, 0 to 100, as on the site (lib/soundLevels.ts): the interface (taps, chimes,
  /// coins) and the stadium (the whistle, the ball, the crowd). The site's third, the commentator, waits for a voice in
  /// the app.
  final int soundUi, soundStadium;

  /// [Sprint 64 F13] The buttons' buzz and tap (GlmButton), one switch, as on the site (lib/soundLevels.ts).
  final bool touch;

  Locale get locale => Locale(language);
  Settings copyWith({ThemeMode? theme, String? language, bool? sounds, int? soundUi, int? soundStadium, bool? touch}) => Settings(
    theme: theme ?? this.theme,
    language: language ?? this.language,
    sounds: sounds ?? this.sounds,
    soundUi: soundUi ?? this.soundUi,
    soundStadium: soundStadium ?? this.soundStadium,
    touch: touch ?? this.touch,
  );
}

final preferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main()'));

final settingsProvider = NotifierProvider<SettingsController, Settings>(SettingsController.new);

class SettingsController extends Notifier<Settings> {
  static const _theme = 'glm.theme';
  static const _language = 'glm.language';
  static const _sounds = 'glm.sounds';
  static const _soundUi = 'glm.sound.ui';
  static const _soundStadium = 'glm.sound.stadium';
  static const _touch = 'glm.touch';

  @override
  Settings build() {
    final p = ref.watch(preferencesProvider);
    final theme = switch (p.getString(_theme)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    return Settings(
      theme: theme,
      language: p.getString(_language) == 'en' ? 'en' : 'ar',
      sounds: p.getBool(_sounds) ?? true,
      soundUi: (p.getInt(_soundUi) ?? 80).clamp(0, 100),
      soundStadium: (p.getInt(_soundStadium) ?? 80).clamp(0, 100),
      touch: p.getBool(_touch) ?? true,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(theme: mode);
    await ref.read(preferencesProvider).setString(_theme, mode.name);
  }

  Future<void> setSounds(bool on) async {
    state = state.copyWith(sounds: on);
    await ref.read(preferencesProvider).setBool(_sounds, on);
  }

  /// [Sprint 63 G13] One of the two levels ('ui' or 'stadium'), 0 to 100.
  Future<void> setLevel(String which, int level) async {
    final v = level.clamp(0, 100);
    state = which == 'ui' ? state.copyWith(soundUi: v) : state.copyWith(soundStadium: v);
    await ref.read(preferencesProvider).setInt(which == 'ui' ? _soundUi : _soundStadium, v);
  }

  /// [Sprint 64 F13] The buttons' buzz and tap.
  Future<void> setTouch(bool on) async {
    state = state.copyWith(touch: on);
    await ref.read(preferencesProvider).setBool(_touch, on);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await ref.read(preferencesProvider).setString(_language, language);
  }
}
