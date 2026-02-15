import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class AppProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;
  int _currentPageIndex = 0;
  bool _sidebarExpanded = true;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  int get currentPageIndex => _currentPageIndex;
  bool get sidebarExpanded => _sidebarExpanded;
  bool get initialized => _initialized;

  AppProvider({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService();

  Future<void> initialize() async {
    if (_initialized) return;

    await _settingsService.initialize();
    _themeMode = _settingsService.getThemeMode();
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
