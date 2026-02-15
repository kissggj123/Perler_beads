import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventory_storage_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryStorageService _storageService = InventoryStorageService();

  Inventory _inventory = Inventory.empty();
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  BeadBrand? _selectedBrand;
  int _lowStockThreshold = 50;

  Inventory get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  BeadBrand? get selectedBrand => _selectedBrand;
  int get lowStockThreshold => _lowStockThreshold;

  List<InventoryItem> get filteredItems {
    var items = _inventory.items;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        final nameMatch = item.beadColor.name.toLowerCase().contains(query);
        final codeMatch = item.beadColor.code.toLowerCase().contains(query);
        final categoryMatch =
            item.beadColor.category?.toLowerCase().contains(query) ?? false;
        return nameMatch || codeMatch || categoryMatch;
      }).toList();
    }

    if (_selectedCategory != null) {
      items = items
          .where((item) => item.beadColor.category == _selectedCategory)
          .toList();
    }

    if (_selectedBrand != null) {
      items = items
          .where((item) => item.beadColor.brand == _selectedBrand)
          .toList();
    }

    return items;
  }

  int get totalQuantity => _inventory.getTotalQuantity();
  int get colorCount => _inventory.itemCount;
  List<InventoryItem> get lowStockItems =>
      _inventory.getLowStockItems(_lowStockThreshold);
  List<InventoryItem> get outOfStockItems => _inventory.getOutOfStockItems();
  bool get hasLowStock => lowStockItems.isNotEmpty;
  bool get hasOutOfStock => outOfStockItems.isNotEmpty;

  List<String> get availableCategories {
    return _inventory.items
        .map((item) => item.beadColor.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<BeadBrand> get availableBrands {
    return _inventory.items
        .map((item) => item.beadColor.brand)
        .toSet()
        .toList();
  }

  Future<void> loadInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loaded = await _storageService.loadInventory();
      _inventory = loaded ?? Inventory.empty();
      _error = null;
    } catch (e) {
      _error = '加载库存失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveInventory() async {
    try {
      await _storageService.saveInventory(_inventory);
    } catch (e) {
      _error = '保存库存失败: $e';
      notifyListeners();
    }
  }

  Future<void> addItem(BeadColor beadColor, int quantity) async {
    final existingItem = _inventory.findByColorCode(beadColor.code);

    if (existingItem != null) {
      _inventory = _inventory.updateQuantity(
        beadColor.code,
        existingItem.quantity + quantity,
      );
    } else {
      final item = InventoryItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_inventory.itemCount}',
        beadColor: beadColor,
        quantity: quantity,
        lastUpdated: DateTime.now(),
      );
      _inventory = _inventory.addItem(item);
    }

    await saveInventory();
    notifyListeners();
  }

  Future<void> removeItem(String itemId) async {
    _inventory = _inventory.removeItem(itemId);
    await saveInventory();
    notifyListeners();
  }

  Future<void> updateQuantity(String colorCode, int newQuantity) async {
    _inventory = _inventory.updateQuantity(colorCode, newQuantity);
    await saveInventory();
    notifyListeners();
  }

  Future<void> updateItem(
    String itemId, {
    BeadColor? beadColor,
    int? quantity,
  }) async {
    final index = _inventory.items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final oldItem = _inventory.items[index];
    final updatedItem = oldItem.copyWith(
      beadColor: beadColor,
      quantity: quantity,
      lastUpdated: DateTime.now(),
    );

    final newItems = List<InventoryItem>.from(_inventory.items);
    newItems[index] = updatedItem;

    _inventory = Inventory(items: newItems, lastUpdated: DateTime.now());

    await saveInventory();
    notifyListeners();
  }

  Future<ImportResult> importFromCsv(String csvContent) async {
    try {
      final imported = await _storageService.importFromCsv(csvContent);
      if (imported == null) {
        return ImportResult(
          success: false,
          message: 'CSV解析失败',
          importedCount: 0,
        );
      }

      int count = 0;
      for (final item in imported.items) {
        final existing = _inventory.findByColorCode(item.beadColor.code);
        if (existing != null) {
          _inventory = _inventory.updateQuantity(
            item.beadColor.code,
            existing.quantity + item.quantity,
          );
        } else {
          _inventory = _inventory.addItem(item);
        }
        count++;
      }

      await saveInventory();
      notifyListeners();
      return ImportResult(success: true, message: '导入成功', importedCount: count);
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入失败: $e',
        importedCount: 0,
      );
    }
  }

  Future<ImportResult> importFromJson(String jsonContent) async {
    try {
      final imported = await _storageService.importFromJson(jsonContent);
      if (imported == null) {
        return ImportResult(
          success: false,
          message: 'JSON解析失败',
          importedCount: 0,
        );
      }

      int count = 0;
      for (final item in imported.items) {
        final existing = _inventory.findByColorCode(item.beadColor.code);
        if (existing != null) {
          _inventory = _inventory.updateQuantity(
            item.beadColor.code,
            existing.quantity + item.quantity,
          );
        } else {
          _inventory = _inventory.addItem(item);
        }
        count++;
      }

      await saveInventory();
      notifyListeners();
      return ImportResult(success: true, message: '导入成功', importedCount: count);
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入失败: $e',
        importedCount: 0,
      );
    }
  }

  Future<String> exportToCsv() async {
    return await _storageService.exportToCsv();
  }

  Future<String> exportToJson() async {
    final json = _inventory.toJson();
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<bool> exportToCsvFile() async {
    return await _storageService.exportToCsvFile();
  }

  Future<bool> exportToJsonFile() async {
    return await _storageService.exportToJsonFile();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setBrand(BeadBrand? brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void setLowStockThreshold(int threshold) {
    _lowStockThreshold = threshold;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedBrand = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  InventoryItem? findByColorCode(String colorCode) {
    return _inventory.findByColorCode(colorCode);
  }

  int getQuantityForColor(String colorCode) {
    return _inventory.getTotalQuantityForColor(colorCode);
  }

  bool hasColor(String colorCode) {
    return _inventory.hasColor(colorCode);
  }

  Future<void> clearInventory() async {
    _inventory = Inventory.empty();
    await _storageService.clearInventory();
    notifyListeners();
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;

  const ImportResult({
    required this.success,
    required this.message,
    required this.importedCount,
  });
}
