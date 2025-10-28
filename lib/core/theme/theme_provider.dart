import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  system, // Follow system settings
  light,  // Always light
  dark,   // Always dark
}

/// Service for persisting theme preferences
class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  
  final SharedPreferences _prefs;
  
  ThemeService(this._prefs);
  
  /// Get saved theme mode
  AppThemeMode getThemeMode() {
    final value = _prefs.getString(_themeKey);
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
  
  /// Save theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    final value = mode.name;
    await _prefs.setString(_themeKey, value);
  }
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provider for ThemeService
final themeServiceProvider = Provider<ThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeService(prefs);
});

/// State notifier for theme management
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final ThemeService _themeService;
  
  ThemeNotifier(this._themeService) : super(_themeService.getThemeMode());
  
  /// Change theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await _themeService.setThemeMode(mode);
  }
  
  /// Toggle between light and dark (keeping system as option)
  Future<void> toggleTheme() async {
    final newMode = switch (state) {
      AppThemeMode.system => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
    };
    await setThemeMode(newMode);
  }
  
  /// Get Flutter's ThemeMode from AppThemeMode
  ThemeMode get flutterThemeMode {
    return switch (state) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeNotifier(themeService);
});
