import 'package:flutter/material.dart';
import '../models/bead_color.dart';
import '../data/standard_colors.dart';
import '../utils/color_utils.dart';

class ColorPaletteProvider extends ChangeNotifier {
  List<BeadColor> _standardPalette = [];
  List<BeadColor> _customColors = [];
  List<BeadColor> _filteredColors = [];
  String _searchQuery = '';
  String? _selectedCategory;
  BeadBrand? _selectedBrand;
  BeadColor? _selectedColor;

  List<BeadColor> get standardPalette => _standardPalette;
  List<BeadColor> get customColors => List.unmodifiable(_customColors);
  List<BeadColor> get filteredColors => _filteredColors;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  BeadBrand? get selectedBrand => _selectedBrand;
  BeadColor? get selectedColor => _selectedColor;
  
  List<BeadColor> get allColors => [..._standardPalette, ..._customColors];
  int get totalColorCount => _standardPalette.length + _customColors.length;
  int get customColorCount => _customColors.length;

  ColorPaletteProvider() {
    loadDefaultPalette();
  }

  void loadDefaultPalette() {
    _standardPalette = List.from(standardColors);
    _customColors = [];
    _applyFilters();
    notifyListeners();
  }

  void addCustomColor(BeadColor color) {
    if (_customColors.any((c) => c.code == color.code)) {
      return;
    }
    _customColors.add(color);
    _applyFilters();
    notifyListeners();
  }

  void addCustomColors(List<BeadColor> colors) {
    for (final color in colors) {
      if (!_customColors.any((c) => c.code == color.code)) {
        _customColors.add(color);
      }
    }
    _applyFilters();
    notifyListeners();
  }

  void removeCustomColor(String code) {
    _customColors.removeWhere((color) => color.code == code);
    _applyFilters();
    notifyListeners();
  }

  void updateCustomColor(String code, BeadColor newColor) {
    final index = _customColors.indexWhere((color) => color.code == code);
    if (index != -1) {
      _customColors[index] = newColor;
      _applyFilters();
      notifyListeners();
    }
  }

  void clearCustomColors() {
    _customColors.clear();
    _applyFilters();
    notifyListeners();
  }

  List<BeadColor> searchColors(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
    return _filteredColors;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setBrand(BeadBrand? brand) {
    _selectedBrand = brand;
    _applyFilters();
    notifyListeners();
  }

  void setSelectedColor(BeadColor? color) {
    _selectedColor = color;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedBrand = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var colors = allColors;

    if (_searchQuery.isNotEmpty) {
      colors = colors.where((color) {
        final nameMatch = color.name.toLowerCase().contains(_searchQuery);
        final codeMatch = color.code.toLowerCase().contains(_searchQuery);
        final categoryMatch = color.category?.toLowerCase().contains(_searchQuery) ?? false;
        return nameMatch || codeMatch || categoryMatch;
      }).toList();
    }

    if (_selectedCategory != null) {
      colors = colors.where((color) => color.category == _selectedCategory).toList();
    }

    if (_selectedBrand != null) {
      colors = colors.where((color) => color.brand == _selectedBrand).toList();
    }

    _filteredColors = colors;
  }

  BeadColor getClosestColor(Color target) {
    return ColorUtils.findClosestColor(target, allColors);
  }

  List<BeadColor> getClosestColors(Color target, {int count = 5}) {
    return ColorUtils.findClosestColors(target, allColors, count: count);
  }

  BeadColor? getColorByCode(String code) {
    try {
      return allColors.firstWhere((color) => color.code == code);
    } catch (e) {
      return null;
    }
  }

  List<BeadColor> getColorsByCategory(String category) {
    return allColors.where((color) => color.category == category).toList();
  }

  List<BeadColor> getColorsByBrand(BeadBrand brand) {
    return allColors.where((color) => color.brand == brand).toList();
  }

  List<String> get availableCategories {
    return allColors
        .map((color) => color.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<BeadBrand> get availableBrands {
    return allColors
        .map((color) => color.brand)
        .toSet()
        .toList();
  }

  Map<String, List<BeadColor>> get colorsGroupedByCategory {
    final Map<String, List<BeadColor>> grouped = {};
    for (final color in allColors) {
      final category = color.category ?? '未分类';
      grouped.putIfAbsent(category, () => []).add(color);
    }
    return grouped;
  }

  Map<BeadBrand, List<BeadColor>> get colorsGroupedByBrand {
    final Map<BeadBrand, List<BeadColor>> grouped = {};
    for (final color in allColors) {
      grouped.putIfAbsent(color.brand, () => []).add(color);
    }
    return grouped;
  }

  bool hasCustomColor(String code) {
    return _customColors.any((color) => color.code == code);
  }

  bool isStandardColor(String code) {
    return _standardPalette.any((color) => color.code == code);
  }

  void importCustomColors(List<Map<String, dynamic>> colorData) {
    for (final data in colorData) {
      try {
        final color = BeadColor.fromJson(data);
        if (!hasCustomColor(color.code) && !isStandardColor(color.code)) {
          _customColors.add(color);
        }
      } catch (e) {
        continue;
      }
    }
    _applyFilters();
    notifyListeners();
  }

  List<Map<String, dynamic>> exportCustomColors() {
    return _customColors.map((color) => color.toJson()).toList();
  }
}
