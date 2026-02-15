import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class AppProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;
  int _currentPageIndex = 0;
  bool _sidebarExpanded = true;
  bool _initialized = false;
  bool _animationsEnabled = true;
  bool _pageTransitionsEnabled = true;
  bool _listAnimationsEnabled = true;
  bool _buttonAnimationsEnabled = true;
  bool _cardAnimationsEnabled = true;
  bool _godModeEnabled = false;
  bool _debugModeEnabled = false;
  bool _performanceMonitorEnabled = false;
  bool _experimentalFeaturesEnabled = false;

  ThemeMode get themeMode => _themeMode;
  int get currentPageIndex => _currentPageIndex;
  bool get sidebarExpanded => _sidebarExpanded;
  bool get initialized => _initialized;
  bool get animationsEnabled => _animationsEnabled;
  bool get pageTransitionsEnabled => _pageTransitionsEnabled;
  bool get listAnimationsEnabled => _listAnimationsEnabled;
  bool get buttonAnimationsEnabled => _buttonAnimationsEnabled;
  bool get cardAnimationsEnabled => _cardAnimationsEnabled;
  bool get godModeEnabled => _godModeEnabled;
  bool get debugModeEnabled => _debugModeEnabled;
  bool get performanceMonitorEnabled => _performanceMonitorEnabled;
  bool get experimentalFeaturesEnabled => _experimentalFeaturesEnabled;

  AppProvider({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  Future<void> initialize() async {
    if (_initialized) return;

    await _settingsService.initialize();
    _themeMode = _settingsService.getThemeMode();
    _animationsEnabled = _settingsService.getAnimationsEnabled();
    _pageTransitionsEnabled = _settingsService.getPageTransitionsEnabled();
    _listAnimationsEnabled = _settingsService.getListAnimationsEnabled();
    _buttonAnimationsEnabled = _settingsService.getButtonAnimationsEnabled();
    _cardAnimationsEnabled = _settingsService.getCardAnimationsEnabled();
    _godModeEnabled = _settingsService.getGodModeEnabled();
    _debugModeEnabled = _settingsService.getDebugModeEnabled();
    _performanceMonitorEnabled = _settingsService
        .getPerformanceMonitorEnabled();
    _experimentalFeaturesEnabled = _settingsService
        .getExperimentalFeaturesEnabled();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _settingsService.setThemeMode(mode);
    notifyListeners();
  }

  void setCurrentPageIndex(int index) {
    if (_currentPageIndex == index) return;
    _currentPageIndex = index;
    notifyListeners();
  }

  void toggleSidebar() {
    _sidebarExpanded = !_sidebarExpanded;
    notifyListeners();
  }

  void setSidebarExpanded(bool expanded) {
    if (_sidebarExpanded == expanded) return;
    _sidebarExpanded = expanded;
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    await _settingsService.setAnimationsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPageTransitionsEnabled(bool enabled) async {
    if (_pageTransitionsEnabled == enabled) return;
    _pageTransitionsEnabled = enabled;
    await _settingsService.setPageTransitionsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setListAnimationsEnabled(bool enabled) async {
    if (_listAnimationsEnabled == enabled) return;
    _listAnimationsEnabled = enabled;
    await _settingsService.setListAnimationsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setButtonAnimationsEnabled(bool enabled) async {
    if (_buttonAnimationsEnabled == enabled) return;
    _buttonAnimationsEnabled = enabled;
    await _settingsService.setButtonAnimationsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setCardAnimationsEnabled(bool enabled) async {
    if (_cardAnimationsEnabled == enabled) return;
    _cardAnimationsEnabled = enabled;
    await _settingsService.setCardAnimationsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setGodModeEnabled(bool enabled) async {
    if (_godModeEnabled == enabled) return;
    _godModeEnabled = enabled;
    await _settingsService.setGodModeEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDebugModeEnabled(bool enabled) async {
    if (_debugModeEnabled == enabled) return;
    _debugModeEnabled = enabled;
    await _settingsService.setDebugModeEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPerformanceMonitorEnabled(bool enabled) async {
    if (_performanceMonitorEnabled == enabled) return;
    _performanceMonitorEnabled = enabled;
    await _settingsService.setPerformanceMonitorEnabled(enabled);
    notifyListeners();
  }

  Future<void> setExperimentalFeaturesEnabled(bool enabled) async {
    if (_experimentalFeaturesEnabled == enabled) return;
    _experimentalFeaturesEnabled = enabled;
    await _settingsService.setExperimentalFeaturesEnabled(enabled);
    notifyListeners();
  }
}

enum AppPage {
  home(0, '首页', Icons.home_outlined, Icons.home),
  inventory(1, '库存管理', Icons.inventory_2_outlined, Icons.inventory_2),
  colors(2, '颜色库', Icons.palette_outlined, Icons.palette),
  settings(3, '设置', Icons.settings_outlined, Icons.settings);

  final int pageIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppPage(this.pageIndex, this.label, this.icon, this.selectedIcon);
}
