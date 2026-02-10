import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

Future<void> _setThemeModePref(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kThemeModeKey, mode.index.toString());
}

Future<ThemeMode> _getThemeModePref() async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(_kThemeModeKey);
  if (s == null) return ThemeMode.system;
  final i = int.tryParse(s);
  if (i == null || i < 0 || i > 2) return ThemeMode.system;
  return ThemeMode.values[i];
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AsyncValue<ThemeMode>>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AsyncValue<ThemeMode>> {
  ThemeModeNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final mode = await _getThemeModePref();
      state = AsyncValue.data(mode);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _setThemeModePref(mode);
    state = AsyncValue.data(mode);
  }
}
