import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [Sprint 15 F1] This phone's choices, as on the web (X56, Sprint 43 A1): the look (the device's by default, or night or
/// day) and the language (Arabic by default). Kept on the phone only.
class Settings {
  const Settings({this.theme = ThemeMode.system, this.language = 'ar'});

  final ThemeMode theme;
  final String language;

  Locale get locale => Locale(language);
  Settings copyWith({ThemeMode? theme, String? language}) => Settings(theme: theme ?? this.theme, language: language ?? this.language);
}

final preferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main()'));

final settingsProvider = NotifierProvider<SettingsController, Settings>(SettingsController.new);

class SettingsController extends Notifier<Settings> {
  static const _theme = 'glm.theme';
  static const _language = 'glm.language';

  @override
  Settings build() {
    final p = ref.watch(preferencesProvider);
    final theme = switch (p.getString(_theme)) { 'dark' => ThemeMode.dark, 'light' => ThemeMode.light, _ => ThemeMode.system };
    return Settings(theme: theme, language: p.getString(_language) == 'en' ? 'en' : 'ar');
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(theme: mode);
    await ref.read(preferencesProvider).setString(_theme, mode.name);
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await ref.read(preferencesProvider).setString(_language, language);
  }
}
