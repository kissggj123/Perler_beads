import 'bead_color.dart';

class InventoryItem {
  final String id;
  final BeadColor beadColor;
  final int quantity;
  final DateTime lastUpdated;

  const InventoryItem({
    required this.id,
    required this.beadColor,
    required this.quantity,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      beadColor: BeadColor.fromJson(json['beadColor'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beadColor': beadColor.toJson(),
      'quantity': quantity,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    BeadColor? beadColor,
    int? quantity,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      beadColor: beadColor ?? this.beadColor,
      quantity: quantity ?? this.quantity,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  InventoryItem addQuantity(int amount) {
    return copyWith(
      quantity: quantity + amount,
      lastUpdated: DateTime.now(),
    );
  }

  InventoryItem subtractQuantity(int amount) {
    final newQuantity = (quantity - amount).clamp(0, quantity);
    return copyWith(
      quantity: newQuantity,
      lastUpdated: DateTime.now(),
    );
  }

  bool get isEmpty => quantity <= 0;

  bool get isNotEmpty => quantity > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryItem(id: $id, beadColor: ${beadColor.name}, quantity: $quantity)';
  }
}
