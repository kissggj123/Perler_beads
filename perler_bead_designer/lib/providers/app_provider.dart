import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class AppProvider extends ChangeNotifier {
  final SettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;
  int _currentPageIndex = 0;
  bool _sidebarExpanded = true;
  bool _sidebarAutoCollapse = true;
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
  bool _showFps = false;
  bool _showGridCoordinates = false;
  bool _showMemoryInfo = false;
  bool _showCacheStats = false;
  bool _showTouchPoints = false;
  bool _showLayoutBounds = false;
  bool _showRepaintRainbow = false;
  bool _enableSlowAnimations = false;
  double _slowAnimationSpeed = 0.5;
  bool _hiddenFeaturesEnabled = false;
  bool _easterEggDiscovered = false;
  bool _debugOverlayEnabled = false;
  bool _showBead3DEffect = true;
  ThemeColors _themeColors = ThemeColors.fromPreset(
    PresetThemeType.defaultPink,
  );
  PresetThemeType _presetTheme = PresetThemeType.defaultPink;
  List<ThemeColors> _savedColorSchemes = [];
  bool _isCustomTheme = false;

  ThemeMode get themeMode => _themeMode;
  int get currentPageIndex => _currentPageIndex;
  bool get sidebarExpanded => _sidebarExpanded;
  bool get sidebarAutoCollapse => _sidebarAutoCollapse;
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
  bool get showFps => _showFps;
  bool get showGridCoordinates => _showGridCoordinates;
  bool get showMemoryInfo => _showMemoryInfo;
  bool get showCacheStats => _showCacheStats;
  bool get showTouchPoints => _showTouchPoints;
  bool get showLayoutBounds => _showLayoutBounds;
  bool get showRepaintRainbow => _showRepaintRainbow;
  bool get enableSlowAnimations => _enableSlowAnimations;
  double get slowAnimationSpeed => _slowAnimationSpeed;
  bool get hiddenFeaturesEnabled => _hiddenFeaturesEnabled;
  bool get easterEggDiscovered => _easterEggDiscovered;
  bool get debugOverlayEnabled => _debugOverlayEnabled;
  bool get showBead3DEffect => _showBead3DEffect;
  ThemeColors get themeColors => _themeColors;
  PresetThemeType get presetTheme => _presetTheme;
  List<ThemeColors> get savedColorSchemes => _savedColorSchemes;
  bool get isCustomTheme => _isCustomTheme;
  double _cellSize = 20.0;
  String _gridColor = '#9E9E9E';
  double _coordinateFontSize = -1;
  double get cellSize => _cellSize;
  String get gridColor => _gridColor;
  double get coordinateFontSize => _coordinateFontSize;
  double get effectiveCoordinateFontSize =>
      _coordinateFontSize > 0 ? _coordinateFontSize : _cellSize * 0.35;

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
    _showFps = _settingsService.getShowFps();
    _showGridCoordinates = _settingsService.getShowGridCoordinates();
    _showMemoryInfo = _settingsService.getShowMemoryInfo();
    _showCacheStats = _settingsService.getShowCacheStats();
    _showTouchPoints = _settingsService.getShowTouchPoints();
    _showLayoutBounds = _settingsService.getShowLayoutBounds();
    _showRepaintRainbow = _settingsService.getShowRepaintRainbow();
    _enableSlowAnimations = _settingsService.getEnableSlowAnimations();
    _slowAnimationSpeed = _settingsService.getSlowAnimationSpeed();
    _hiddenFeaturesEnabled = _settingsService.getHiddenFeaturesEnabled();
    _easterEggDiscovered = _settingsService.getEasterEggDiscovered();
    _debugOverlayEnabled = _settingsService.getDebugOverlayEnabled();
    _showBead3DEffect = _settingsService.getShowBead3DEffect();
    _themeColors = _settingsService.getThemeColors();
    _presetTheme = _settingsService.getPresetTheme();
    _savedColorSchemes = _settingsService.getSavedColorSchemes();
    _cellSize = _settingsService.getCellSize();
    _gridColor = _settingsService.getGridColor();
    _coordinateFontSize = _settingsService.getCoordinateFontSize();
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

  void setSidebarAutoCollapse(bool enabled) {
    if (_sidebarAutoCollapse == enabled) return;
    _sidebarAutoCollapse = enabled;
    notifyListeners();
  }

  void updateSidebarForWidth(
    double width, {
    double collapseThreshold = 1300.0,
  }) {
    if (!_sidebarAutoCollapse) return;

    final shouldCollapse = width < collapseThreshold;
    if (shouldCollapse != !_sidebarExpanded) {
      _sidebarExpanded = !shouldCollapse;
      notifyListeners();
    }
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

  Future<void> setShowFps(bool enabled) async {
    if (_showFps == enabled) return;
    _showFps = enabled;
    await _settingsService.setShowFps(enabled);
    notifyListeners();
  }

  Future<void> setShowGridCoordinates(bool enabled) async {
    if (_showGridCoordinates == enabled) return;
    _showGridCoordinates = enabled;
    await _settingsService.setShowGridCoordinates(enabled);
    notifyListeners();
  }

  Future<void> setShowMemoryInfo(bool enabled) async {
    if (_showMemoryInfo == enabled) return;
    _showMemoryInfo = enabled;
    await _settingsService.setShowMemoryInfo(enabled);
    notifyListeners();
  }

  Future<void> setShowCacheStats(bool enabled) async {
    if (_showCacheStats == enabled) return;
    _showCacheStats = enabled;
    await _settingsService.setShowCacheStats(enabled);
    notifyListeners();
  }

  Future<void> setShowTouchPoints(bool enabled) async {
    if (_showTouchPoints == enabled) return;
    _showTouchPoints = enabled;
    await _settingsService.setShowTouchPoints(enabled);
    notifyListeners();
  }

  Future<void> setShowLayoutBounds(bool enabled) async {
    if (_showLayoutBounds == enabled) return;
    _showLayoutBounds = enabled;
    await _settingsService.setShowLayoutBounds(enabled);
    notifyListeners();
  }

  Future<void> setShowRepaintRainbow(bool enabled) async {
    if (_showRepaintRainbow == enabled) return;
    _showRepaintRainbow = enabled;
    await _settingsService.setShowRepaintRainbow(enabled);
    notifyListeners();
  }

  Future<void> setEnableSlowAnimations(bool enabled) async {
    if (_enableSlowAnimations == enabled) return;
    _enableSlowAnimations = enabled;
    await _settingsService.setEnableSlowAnimations(enabled);
    notifyListeners();
  }

  void setSlowAnimationSpeedImmediate(double speed) {
    if (_slowAnimationSpeed == speed) return;
    _slowAnimationSpeed = speed;
    notifyListeners();
  }

  Future<void> setSlowAnimationSpeed(double speed) async {
    if (_slowAnimationSpeed == speed) return;
    _slowAnimationSpeed = speed;
    await _settingsService.setSlowAnimationSpeed(speed);
    notifyListeners();
  }

  Future<void> setHiddenFeaturesEnabled(bool enabled) async {
    if (_hiddenFeaturesEnabled == enabled) return;
    _hiddenFeaturesEnabled = enabled;
    await _settingsService.setHiddenFeaturesEnabled(enabled);
    notifyListeners();
  }

  Future<void> setEasterEggDiscovered(bool discovered) async {
    if (_easterEggDiscovered == discovered) return;
    _easterEggDiscovered = discovered;
    await _settingsService.setEasterEggDiscovered(discovered);
    notifyListeners();
  }

  Future<void> setDebugOverlayEnabled(bool enabled) async {
    if (_debugOverlayEnabled == enabled) return;
    _debugOverlayEnabled = enabled;
    await _settingsService.setDebugOverlayEnabled(enabled);
    notifyListeners();
  }

  Future<void> setShowBead3DEffect(bool enabled) async {
    if (_showBead3DEffect == enabled) return;
    _showBead3DEffect = enabled;
    await _settingsService.setShowBead3DEffect(enabled);
    notifyListeners();
  }

  Future<void> setThemeColors(ThemeColors colors) async {
    _themeColors = colors;
    _isCustomTheme = true;
    await _settingsService.setThemeColors(colors);
    notifyListeners();
  }

  Future<void> setThemeColorsImmediate(ThemeColors colors) async {
    _themeColors = colors;
    _isCustomTheme = true;
    notifyListeners();
    await _settingsService.setThemeColors(colors);
  }

  Future<void> setPresetTheme(PresetThemeType preset) async {
    _presetTheme = preset;
    _themeColors = ThemeColors.fromPreset(preset);
    _isCustomTheme = false;
    await _settingsService.setPresetTheme(preset);
    await _settingsService.setThemeColors(_themeColors);
    notifyListeners();
  }

  Future<void> setCustomThemeColors({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    String? name,
  }) async {
    _themeColors = ThemeColors(
      primaryColor: primaryColor ?? _themeColors.primaryColor,
      secondaryColor: secondaryColor ?? _themeColors.secondaryColor,
      accentColor: accentColor ?? _themeColors.accentColor,
      name: name ?? _themeColors.name,
    );
    _isCustomTheme = true;
    await _settingsService.setThemeColors(_themeColors);
    notifyListeners();
  }

  void updatePrimaryColorImmediate(Color color) {
    _themeColors = ThemeColors(
      primaryColor: color,
      secondaryColor: _themeColors.secondaryColor,
      accentColor: _themeColors.accentColor,
      name: _themeColors.name,
    );
    _isCustomTheme = true;
    notifyListeners();
  }

  void updateSecondaryColorImmediate(Color color) {
    _themeColors = ThemeColors(
      primaryColor: _themeColors.primaryColor,
      secondaryColor: color,
      accentColor: _themeColors.accentColor,
      name: _themeColors.name,
    );
    _isCustomTheme = true;
    notifyListeners();
  }

  void updateAccentColorImmediate(Color color) {
    _themeColors = ThemeColors(
      primaryColor: _themeColors.primaryColor,
      secondaryColor: _themeColors.secondaryColor,
      accentColor: color,
      name: _themeColors.name,
    );
    _isCustomTheme = true;
    notifyListeners();
  }

  Future<void> persistThemeColors() async {
    await _settingsService.setThemeColors(_themeColors);
  }

  Future<void> saveCurrentColorScheme(String name) async {
    final newScheme = ThemeColors(
      primaryColor: _themeColors.primaryColor,
      secondaryColor: _themeColors.secondaryColor,
      accentColor: _themeColors.accentColor,
      name: name,
    );
    _savedColorSchemes.add(newScheme);
    await _settingsService.setSavedColorSchemes(_savedColorSchemes);
    notifyListeners();
  }

  Future<void> loadSavedColorScheme(int index) async {
    if (index >= 0 && index < _savedColorSchemes.length) {
      _themeColors = _savedColorSchemes[index];
      await _settingsService.setThemeColors(_themeColors);
      notifyListeners();
    }
  }

  Future<void> deleteSavedColorScheme(int index) async {
    if (index >= 0 && index < _savedColorSchemes.length) {
      _savedColorSchemes.removeAt(index);
      await _settingsService.setSavedColorSchemes(_savedColorSchemes);
      notifyListeners();
    }
  }

  void setCellSizeImmediate(double size) {
    if (_cellSize == size) return;
    _cellSize = size;
    notifyListeners();
  }

  Future<void> setCellSize(double size) async {
    if (_cellSize == size) return;
    _cellSize = size;
    await _settingsService.setCellSize(size);
    notifyListeners();
  }

  Future<void> setGridColor(String color) async {
    if (_gridColor == color) return;
    _gridColor = color;
    await _settingsService.setGridColor(color);
    notifyListeners();
  }

  void setCoordinateFontSizeImmediate(double size) {
    if (_coordinateFontSize == size) return;
    _coordinateFontSize = size;
    notifyListeners();
  }

  Future<void> setCoordinateFontSize(double size) async {
    if (_coordinateFontSize == size) return;
    _coordinateFontSize = size;
    await _settingsService.setCoordinateFontSize(size);
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
