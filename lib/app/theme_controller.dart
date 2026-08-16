import 'package:flutter/material.dart';

import '../storage/app_storage.dart';

/// Persists the user's light/dark choice across restarts. Defaults to dark.
class ThemeController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeController() : _themeMode = _loadThemeMode();

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  static ThemeMode _loadThemeMode() {
    final stored = AppStorage.settings.get(_themeModeKey) as String?;
    return stored == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await AppStorage.settings.put(_themeModeKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
