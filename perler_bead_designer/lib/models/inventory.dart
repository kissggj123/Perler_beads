import 'inventory_item.dart';

class Inventory {
  final List<InventoryItem> items;
  final DateTime lastUpdated;

  const Inventory({required this.items, required this.lastUpdated});

  factory Inventory.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return Inventory(
      items: itemsList
          .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  Inventory addItem(InventoryItem item) {
    final existingIndex = items.indexWhere(
      (i) => i.beadColor.code == item.beadColor.code,
    );
    List<InventoryItem> newItems;

    if (existingIndex >= 0) {
      newItems = List<InventoryItem>.from(items);
      newItems[existingIndex] = newItems[existingIndex].addQuantity(
        item.quantity,
      );
    } else {
      newItems = [...items, item];
    }

    return Inventory(items: newItems, lastUpdated: DateTime.now());
  }

  Inventory removeItem(String itemId) {
    return Inventory(
      items: items.where((item) => item.id != itemId).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  Inventory updateQuantity(String colorCode, int newQuantity) {
    final newItems = items.map((item) {
      if (item.beadColor.code == colorCode) {
        return item.copyWith(
          quantity: newQuantity,
          lastUpdated: DateTime.now(),
        );
      }
      return item;
    }).toList();

    return Inventory(items: newItems, lastUpdated: DateTime.now());
  }

  InventoryItem? findByColorCode(String colorCode) {
    try {
      return items.firstWhere((item) => item.beadColor.code == colorCode);
    } catch (_) {
      return null;
    }
  }

  int getTotalQuantity() {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int getTotalQuantityForColor(String colorCode) {
    final item = findByColorCode(colorCode);
    return item?.quantity ?? 0;
  }

  bool hasColor(String colorCode) {
    return items.any((item) => item.beadColor.code == colorCode);
  }

  List<InventoryItem> getLowStockItems(int threshold) {
    return items.where((item) => item.quantity <= threshold).toList();
  }

  List<InventoryItem> getOutOfStockItems() {
    return items.where((item) => item.isEmpty).toList();
  }

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  int getUniqueColorCount() {
    return items.length;
  }

  bool hasSufficientQuantity(String colorCode, int quantity) {
    final currentQuantity = getTotalQuantityForColor(colorCode);
    return currentQuantity >= quantity;
  }

  bool isLowStock(String colorCode, int threshold) {
    final currentQuantity = getTotalQuantityForColor(colorCode);
    return currentQuantity <= threshold;
  }

  Inventory copyWith({List<InventoryItem>? items, DateTime? lastUpdated}) {
    return Inventory(
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static Inventory empty() {
    return Inventory(items: const [], lastUpdated: DateTime.now());
  }

  int getTotalItems() {
    return items.length;
  }

  InventoryItem? updateItem(String itemId, int newQuantity) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index == -1) return null;

    final updatedItems = List<InventoryItem>.from(items);
    updatedItems[index] = updatedItems[index].copyWith(
      quantity: newQuantity,
      lastUpdated: DateTime.now(),
    );

    return updatedItems[index];
  }

  @override
  String toString() {
    return 'Inventory(itemCount: $itemCount, totalQuantity: ${getTotalQuantity()})';
  }
}
