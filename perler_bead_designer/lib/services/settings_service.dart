import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

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
}
