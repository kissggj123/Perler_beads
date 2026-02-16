import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

enum PresetThemeType {
  defaultPink,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  lavender,
  darkMode,
  lightMode,
  eyeCare,
  highContrast,
}

class ThemeColors {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String name;

  const ThemeColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.name,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      accentColor: Color(json['accentColor'] as int),
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'name': name,
    };
  }

  static ThemeColors fromPreset(PresetThemeType preset) {
    switch (preset) {
      case PresetThemeType.defaultPink:
        return const ThemeColors(
          primaryColor: Color(0xFFE91E63),
          secondaryColor: Color(0xFFEC407A),
          accentColor: Color(0xFFF48FB1),
          name: '默认粉色',
        );
      case PresetThemeType.oceanBlue:
        return const ThemeColors(
          primaryColor: Color(0xFF2196F3),
          secondaryColor: Color(0xFF42A5F5),
          accentColor: Color(0xFF90CAF9),
          name: '海洋蓝',
        );
      case PresetThemeType.forestGreen:
        return const ThemeColors(
          primaryColor: Color(0xFF4CAF50),
          secondaryColor: Color(0xFF66BB6A),
          accentColor: Color(0xFFA5D6A7),
          name: '森林绿',
        );
      case PresetThemeType.sunsetOrange:
        return const ThemeColors(
          primaryColor: Color(0xFFFF9800),
          secondaryColor: Color(0xFFFFB74D),
          accentColor: Color(0xFFFFCC80),
          name: '日落橙',
        );
      case PresetThemeType.lavender:
        return const ThemeColors(
          primaryColor: Color(0xFF9C27B0),
          secondaryColor: Color(0xFFBA68C8),
          accentColor: Color(0xFFCE93D8),
          name: '薰衣草',
        );
      case PresetThemeType.darkMode:
        return const ThemeColors(
          primaryColor: Color(0xFF6750A4),
          secondaryColor: Color(0xFF9A82DB),
          accentColor: Color(0xFFD0BCFF),
          name: '深色模式',
        );
      case PresetThemeType.lightMode:
        return const ThemeColors(
          primaryColor: Color(0xFF6750A4),
          secondaryColor: Color(0xFF625B71),
          accentColor: Color(0xFF7D5260),
          name: '浅色模式',
        );
      case PresetThemeType.eyeCare:
        return const ThemeColors(
          primaryColor: Color(0xFF8D6E63),
          secondaryColor: Color(0xFFA1887F),
          accentColor: Color(0xFFBCAAA4),
          name: '护眼模式',
        );
      case PresetThemeType.highContrast:
        return const ThemeColors(
          primaryColor: Color(0xFF000000),
          secondaryColor: Color(0xFF333333),
          accentColor: Color(0xFF666666),
          name: '高对比度',
        );
    }
  }
}

class SettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultPaletteKey = 'default_palette';
  static const String _exportShowGridKey = 'export_show_grid';
  static const String _exportPdfIncludeStatsKey = 'export_pdf_include_stats';
  static const String _animationsEnabledKey = 'animations_enabled';
  static const String _pageTransitionsEnabledKey = 'page_transitions_enabled';
  static const String _listAnimationsEnabledKey = 'list_animations_enabled';
  static const String _buttonAnimationsEnabledKey = 'button_animations_enabled';
  static const String _cardAnimationsEnabledKey = 'card_animations_enabled';
  static const String _defaultCanvasWidthKey = 'default_canvas_width';
  static const String _defaultCanvasHeightKey = 'default_canvas_height';
  static const String _lowStockThresholdKey = 'low_stock_threshold';
  static const String _defaultExportFormatKey = 'default_export_format';
  static const String _godModeEnabledKey = 'god_mode_enabled';
  static const String _debugModeEnabledKey = 'debug_mode_enabled';
  static const String _performanceMonitorEnabledKey =
      'performance_monitor_enabled';
  static const String _experimentalFeaturesEnabledKey =
      'experimental_features_enabled';
  static const String _showFpsKey = 'show_fps';
  static const String _showGridCoordinatesKey = 'show_grid_coordinates';
  static const String _showMemoryInfoKey = 'show_memory_info';
  static const String _showCacheStatsKey = 'show_cache_stats';
  static const String _showTouchPointsKey = 'show_touch_points';
  static const String _showLayoutBoundsKey = 'show_layout_bounds';
  static const String _showRepaintRainbowKey = 'show_repaint_rainbow';
  static const String _enableSlowAnimationsKey = 'enable_slow_animations';
  static const String _slowAnimationSpeedKey = 'slow_animation_speed';
  static const String _hiddenFeaturesEnabledKey = 'hidden_features_enabled';
  static const String _easterEggDiscoveredKey = 'easter_egg_discovered';
  static const String _debugOverlayEnabledKey = 'debug_overlay_enabled';
  static const String _showBead3DEffectKey = 'show_bead_3d_effect';
  static const String _themeColorsKey = 'theme_colors';
  static const String _presetThemeKey = 'preset_theme';
  static const String _savedColorSchemesKey = 'saved_color_schemes';
  static const String _cellSizeKey = 'cell_size';
  static const String _gridColorKey = 'grid_color';
  static const String _coordinateFontSizeKey = 'coordinate_font_size';
  static const String _autoSaveIntervalKey = 'auto_save_interval';
  static const String _maxHistorySizeKey = 'max_history_size';

  SharedPreferences? _prefs;

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'SettingsService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  ThemeMode getThemeMode() {
    final themeModeString = prefs.getString(_themeModeKey);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeModeString);
  }

  List<BeadColor>? getDefaultPalette() {
    final paletteJson = prefs.getString(_defaultPaletteKey);
    if (paletteJson == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(paletteJson) as List<dynamic>;
      return jsonList
          .map((json) => BeadColor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> setDefaultPalette(List<BeadColor> palette) async {
    final jsonList = palette.map((color) => color.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_defaultPaletteKey, jsonString);
  }

  Future<void> clearDefaultPalette() async {
    await prefs.remove(_defaultPaletteKey);
  }

  bool getExportShowGrid() {
    return prefs.getBool(_exportShowGridKey) ?? false;
  }

  Future<void> setExportShowGrid(bool value) async {
    await prefs.setBool(_exportShowGridKey, value);
  }

  bool getExportPdfIncludeStats() {
    return prefs.getBool(_exportPdfIncludeStatsKey) ?? true;
  }

  Future<void> setExportPdfIncludeStats(bool value) async {
    await prefs.setBool(_exportPdfIncludeStatsKey, value);
  }

  int getDefaultCanvasWidth() {
    return prefs.getInt(_defaultCanvasWidthKey) ?? 29;
  }

  Future<void> setDefaultCanvasWidth(int value) async {
    await prefs.setInt(_defaultCanvasWidthKey, value);
  }

  int getDefaultCanvasHeight() {
    return prefs.getInt(_defaultCanvasHeightKey) ?? 29;
  }

  Future<void> setDefaultCanvasHeight(int value) async {
    await prefs.setInt(_defaultCanvasHeightKey, value);
  }

  int getLowStockThreshold() {
    return prefs.getInt(_lowStockThresholdKey) ?? 50;
  }

  Future<void> setLowStockThreshold(int value) async {
    await prefs.setInt(_lowStockThresholdKey, value);
  }

  String getDefaultExportFormat() {
    return prefs.getString(_defaultExportFormatKey) ?? 'png';
  }

  Future<void> setDefaultExportFormat(String value) async {
    await prefs.setString(_defaultExportFormatKey, value);
  }

  bool getAnimationsEnabled() {
    return prefs.getBool(_animationsEnabledKey) ?? true;
  }

  Future<void> setAnimationsEnabled(bool value) async {
    await prefs.setBool(_animationsEnabledKey, value);
  }

  bool getPageTransitionsEnabled() {
    return prefs.getBool(_pageTransitionsEnabledKey) ?? true;
  }

  Future<void> setPageTransitionsEnabled(bool value) async {
    await prefs.setBool(_pageTransitionsEnabledKey, value);
  }

  bool getListAnimationsEnabled() {
    return prefs.getBool(_listAnimationsEnabledKey) ?? true;
  }

  Future<void> setListAnimationsEnabled(bool value) async {
    await prefs.setBool(_listAnimationsEnabledKey, value);
  }

  bool getButtonAnimationsEnabled() {
    return prefs.getBool(_buttonAnimationsEnabledKey) ?? true;
  }

  Future<void> setButtonAnimationsEnabled(bool value) async {
    await prefs.setBool(_buttonAnimationsEnabledKey, value);
  }

  bool getCardAnimationsEnabled() {
    return prefs.getBool(_cardAnimationsEnabledKey) ?? true;
  }

  Future<void> setCardAnimationsEnabled(bool value) async {
    await prefs.setBool(_cardAnimationsEnabledKey, value);
  }

  Future<void> setStringSetting(String key, String value) async {
    await prefs.setString(key, value);
  }

  String? getStringSetting(String key) {
    return prefs.getString(key);
  }

  Future<void> setIntSetting(String key, int value) async {
    await prefs.setInt(key, value);
  }

  int? getIntSetting(String key) {
    return prefs.getInt(key);
  }

  Future<void> setBoolSetting(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  bool? getBoolSetting(String key) {
    return prefs.getBool(key);
  }

  Future<void> setDoubleSetting(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  double? getDoubleSetting(String key) {
    return prefs.getDouble(key);
  }

  Future<void> setStringListSetting(String key, List<String> value) async {
    await prefs.setStringList(key, value);
  }

  List<String>? getStringListSetting(String key) {
    return prefs.getStringList(key);
  }

  Future<void> removeSetting(String key) async {
    await prefs.remove(key);
  }

  Future<void> clearAllSettings() async {
    await prefs.clear();
  }

  bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  bool getGodModeEnabled() {
    return prefs.getBool(_godModeEnabledKey) ?? false;
  }

  Future<void> setGodModeEnabled(bool value) async {
    await prefs.setBool(_godModeEnabledKey, value);
  }

  bool getDebugModeEnabled() {
    return prefs.getBool(_debugModeEnabledKey) ?? false;
  }

  Future<void> setDebugModeEnabled(bool value) async {
    await prefs.setBool(_debugModeEnabledKey, value);
  }

  bool getPerformanceMonitorEnabled() {
    return prefs.getBool(_performanceMonitorEnabledKey) ?? false;
  }

  Future<void> setPerformanceMonitorEnabled(bool value) async {
    await prefs.setBool(_performanceMonitorEnabledKey, value);
  }

  bool getExperimentalFeaturesEnabled() {
    return prefs.getBool(_experimentalFeaturesEnabledKey) ?? false;
  }

  Future<void> setExperimentalFeaturesEnabled(bool value) async {
    await prefs.setBool(_experimentalFeaturesEnabledKey, value);
  }

  bool getShowFps() {
    return prefs.getBool(_showFpsKey) ?? false;
  }

  Future<void> setShowFps(bool value) async {
    await prefs.setBool(_showFpsKey, value);
  }

  bool getShowGridCoordinates() {
    return prefs.getBool(_showGridCoordinatesKey) ?? false;
  }

  Future<void> setShowGridCoordinates(bool value) async {
    await prefs.setBool(_showGridCoordinatesKey, value);
  }

  bool getShowMemoryInfo() {
    return prefs.getBool(_showMemoryInfoKey) ?? false;
  }

  Future<void> setShowMemoryInfo(bool value) async {
    await prefs.setBool(_showMemoryInfoKey, value);
  }

  bool getShowCacheStats() {
    return prefs.getBool(_showCacheStatsKey) ?? false;
  }

  Future<void> setShowCacheStats(bool value) async {
    await prefs.setBool(_showCacheStatsKey, value);
  }

  bool getShowTouchPoints() {
    return prefs.getBool(_showTouchPointsKey) ?? false;
  }

  Future<void> setShowTouchPoints(bool value) async {
    await prefs.setBool(_showTouchPointsKey, value);
  }

  bool getShowLayoutBounds() {
    return prefs.getBool(_showLayoutBoundsKey) ?? false;
  }

  Future<void> setShowLayoutBounds(bool value) async {
    await prefs.setBool(_showLayoutBoundsKey, value);
  }

  bool getShowRepaintRainbow() {
    return prefs.getBool(_showRepaintRainbowKey) ?? false;
  }

  Future<void> setShowRepaintRainbow(bool value) async {
    await prefs.setBool(_showRepaintRainbowKey, value);
  }

  bool getEnableSlowAnimations() {
    return prefs.getBool(_enableSlowAnimationsKey) ?? false;
  }

  Future<void> setEnableSlowAnimations(bool value) async {
    await prefs.setBool(_enableSlowAnimationsKey, value);
  }

  double getSlowAnimationSpeed() {
    return prefs.getDouble(_slowAnimationSpeedKey) ?? 0.5;
  }

  Future<void> setSlowAnimationSpeed(double value) async {
    await prefs.setDouble(_slowAnimationSpeedKey, value);
  }

  bool getHiddenFeaturesEnabled() {
    return prefs.getBool(_hiddenFeaturesEnabledKey) ?? false;
  }

  Future<void> setHiddenFeaturesEnabled(bool value) async {
    await prefs.setBool(_hiddenFeaturesEnabledKey, value);
  }

  bool getEasterEggDiscovered() {
    return prefs.getBool(_easterEggDiscoveredKey) ?? false;
  }

  Future<void> setEasterEggDiscovered(bool value) async {
    await prefs.setBool(_easterEggDiscoveredKey, value);
  }

  bool getDebugOverlayEnabled() {
    return prefs.getBool(_debugOverlayEnabledKey) ?? false;
  }

  Future<void> setDebugOverlayEnabled(bool value) async {
    await prefs.setBool(_debugOverlayEnabledKey, value);
  }

  bool getShowBead3DEffect() {
    return prefs.getBool(_showBead3DEffectKey) ?? true;
  }

  Future<void> setShowBead3DEffect(bool value) async {
    await prefs.setBool(_showBead3DEffectKey, value);
  }

  ThemeColors getThemeColors() {
    final themeColorsJson = prefs.getString(_themeColorsKey);
    if (themeColorsJson == null) {
      return ThemeColors.fromPreset(PresetThemeType.defaultPink);
    }
    try {
      return ThemeColors.fromJson(
        jsonDecode(themeColorsJson) as Map<String, dynamic>,
      );
    } catch (e) {
      return ThemeColors.fromPreset(PresetThemeType.defaultPink);
    }
  }

  Future<void> setThemeColors(ThemeColors colors) async {
    final jsonString = jsonEncode(colors.toJson());
    await prefs.setString(_themeColorsKey, jsonString);
  }

  PresetThemeType getPresetTheme() {
    final presetString = prefs.getString(_presetThemeKey);
    if (presetString == null) {
      return PresetThemeType.defaultPink;
    }
    try {
      return PresetThemeType.values.firstWhere(
        (e) => e.name == presetString,
        orElse: () => PresetThemeType.defaultPink,
      );
    } catch (e) {
      return PresetThemeType.defaultPink;
    }
  }

  Future<void> setPresetTheme(PresetThemeType preset) async {
    await prefs.setString(_presetThemeKey, preset.name);
  }

  List<ThemeColors> getSavedColorSchemes() {
    final schemesJson = prefs.getString(_savedColorSchemesKey);
    if (schemesJson == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(schemesJson) as List<dynamic>;
      return jsonList
          .map((json) => ThemeColors.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> setSavedColorSchemes(List<ThemeColors> schemes) async {
    final jsonList = schemes.map((scheme) => scheme.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_savedColorSchemesKey, jsonString);
  }

  Future<void> addSavedColorScheme(ThemeColors scheme) async {
    final schemes = getSavedColorSchemes();
    schemes.add(scheme);
    await setSavedColorSchemes(schemes);
  }

  Future<void> removeSavedColorScheme(int index) async {
    final schemes = getSavedColorSchemes();
    if (index >= 0 && index < schemes.length) {
      schemes.removeAt(index);
      await setSavedColorSchemes(schemes);
    }
  }

  double getCellSize() {
    return prefs.getDouble(_cellSizeKey) ?? 20.0;
  }

  Future<void> setCellSize(double value) async {
    await prefs.setDouble(_cellSizeKey, value);
  }

  String getGridColor() {
    return prefs.getString(_gridColorKey) ?? '#9E9E9E';
  }

  Future<void> setGridColor(String value) async {
    await prefs.setString(_gridColorKey, value);
  }

  double getCoordinateFontSize() {
    return prefs.getDouble(_coordinateFontSizeKey) ?? -1;
  }

  Future<void> setCoordinateFontSize(double value) async {
    await prefs.setDouble(_coordinateFontSizeKey, value);
  }

  int getAutoSaveInterval() {
    return prefs.getInt(_autoSaveIntervalKey) ?? 30;
  }

  Future<void> setAutoSaveInterval(int value) async {
    await prefs.setInt(_autoSaveIntervalKey, value);
  }

  int getMaxHistorySize() {
    return prefs.getInt(_maxHistorySizeKey) ?? 50;
  }

  Future<void> setMaxHistorySize(int value) async {
    await prefs.setInt(_maxHistorySizeKey, value);
  }
}
