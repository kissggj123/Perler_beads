import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class SettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultPaletteKey = 'default_palette';
  static const String _exportShowGridKey = 'export_show_grid';
  static const String _exportPdfIncludeStatsKey = 'export_pdf_include_stats';

  SharedPreferences? _prefs;

  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SettingsService not initialized. Call initialize() first.');
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
}
