import 'package:flutter_test/flutter_test.dart';
import 'package:bunnycc_perler/models/models.dart';

void main() {
  group('BeadColor Model Tests', () {
    test('BeadColor 创建和序列化', () {
      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );

      expect(color.code, '001');
      expect(color.name, '红色');
      expect(color.red, 255);
      expect(color.green, 0);
      expect(color.blue, 0);

      final json = color.toJson();
      expect(json['code'], '001');
      expect(json['name'], '红色');

      final restoredColor = BeadColor.fromJson(json);
      expect(restoredColor.code, color.code);
      expect(restoredColor.name, color.name);
    });

    test('BeadColor 颜色属性', () {
      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );

      expect(color.hexCode, '#FF0000');
      expect(color.r, 255);
      expect(color.g, 0);
      expect(color.b, 0);
      expect(color.isLight, false);
      expect(color.isDark, true);
    });

    test('BeadColor 颜色比较', () {
      final color1 = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final color2 = BeadColor(
        code: '002',
        name: '绿色',
        red: 0,
        green: 255,
        blue: 0,
      );

      expect(color1 == color2, false);
      expect(color1 == color1, true);
    });
  });

  group('BeadDesign Model Tests', () {
    test('BeadDesign 创建和基本属性', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 10,
        height: 10,
      );

      expect(design.id, 'test_123');
      expect(design.name, '测试设计');
      expect(design.width, 10);
      expect(design.height, 10);
      expect(design.getTotalBeadCount(), 0);
    });

    test('BeadDesign 设置和获取拼豆', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 10,
        height: 10,
      );

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final newDesign = design.setBead(5, 5, color);

      expect(newDesign.getBead(5, 5), color);
      expect(newDesign.getBead(0, 0), isNull);
    });

    test('BeadDesign 边界检查', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 10,
        height: 10,
      );

      expect(design.isValidPosition(0, 0), true);
      expect(design.isValidPosition(9, 9), true);
      expect(design.isValidPosition(10, 10), false);
      expect(design.isValidPosition(-1, -1), false);
    });

    test('BeadDesign 清除和填充', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 10,
        height: 10,
      );

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      var newDesign = design.setBead(5, 5, color);
      expect(newDesign.getTotalBeadCount(), 1);

      newDesign = newDesign.clearBead(5, 5);
      expect(newDesign.getTotalBeadCount(), 0);

      newDesign = newDesign.fillAll(color);
      expect(newDesign.getTotalBeadCount(), 100);
    });

    test('BeadDesign 变换操作', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 3,
        height: 2,
      );

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      var newDesign = design.setBead(0, 0, color);

      expect(newDesign.width, 3);
      expect(newDesign.height, 2);

      newDesign = newDesign.flipHorizontal();
      expect(newDesign.getBead(0, 0), isNull);
      expect(newDesign.getBead(2, 0), color);

      newDesign = newDesign.flipVertical();
      expect(newDesign.getBead(2, 1), color);
      expect(newDesign.getBead(2, 0), isNull);

      newDesign = newDesign.resize(5, 3);
      expect(newDesign.width, 5);
      expect(newDesign.height, 3);
    });

    test('BeadDesign 统计信息', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 10,
        height: 10,
      );

      final color1 = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final color2 = BeadColor(
        code: '002',
        name: '绿色',
        red: 0,
        green: 255,
        blue: 0,
      );

      var newDesign = design
          .setBead(0, 0, color1)
          .setBead(1, 0, color1)
          .setBead(2, 0, color2);

      expect(newDesign.getTotalBeadCount(), 3);
      expect(newDesign.getUniqueColorCount(), 2);

      final counts = newDesign.getBeadCountsWithColors();
      expect(counts[color1], 2);
      expect(counts[color2], 1);
    });

    test('BeadDesign JSON 序列化', () {
      final design = BeadDesign.create(
        id: 'test_123',
        name: '测试设计',
        width: 5,
        height: 5,
      );

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final newDesign = design.setBead(2, 2, color);

      final json = newDesign.toJson();
      expect(json['id'], 'test_123');
      expect(json['name'], '测试设计');
      expect(json['width'], 5);
      expect(json['height'], 5);

      final restoredDesign = BeadDesign.fromJson(json);
      expect(restoredDesign.id, newDesign.id);
      expect(restoredDesign.name, newDesign.name);
      expect(restoredDesign.getBead(2, 2), color);
    });
  });

  group('Inventory Model Tests', () {
    test('Inventory 创建和基本操作', () {
      final inventory = Inventory.empty();

      expect(inventory.items, isEmpty);
      expect(inventory.itemCount, 0);
    });

    test('Inventory 添加和删除项目', () {
      final inventory = Inventory.empty();

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final item = InventoryItem(
        id: 'item_1',
        beadColor: color,
        quantity: 100,
        lastUpdated: DateTime.now(),
      );

      final newInventory = inventory.addItem(item);
      expect(newInventory.itemCount, 1);
      expect(newInventory.getTotalQuantityForColor(color.code), 100);

      final _ = item.copyWith(quantity: 150);
      final updatedInventory = newInventory.updateQuantity(color.code, 150);
      expect(updatedInventory.getTotalQuantityForColor(color.code), 150);

      final removedInventory = updatedInventory.removeItem(item.id);
      expect(removedInventory.itemCount, 0);
    });

    test('Inventory 批量操作', () {
      final inventory = Inventory.empty();

      final color1 = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final color2 = BeadColor(
        code: '002',
        name: '绿色',
        red: 0,
        green: 255,
        blue: 0,
      );
      final color3 = BeadColor(
        code: '003',
        name: '蓝色',
        red: 0,
        green: 0,
        blue: 255,
      );

      final items = [
        InventoryItem(
          id: 'item_1',
          beadColor: color1,
          quantity: 100,
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'item_2',
          beadColor: color2,
          quantity: 200,
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'item_3',
          beadColor: color3,
          quantity: 300,
          lastUpdated: DateTime.now(),
        ),
      ];

      var newInventory = inventory;
      for (final item in items) {
        newInventory = newInventory.addItem(item);
      }

      expect(newInventory.itemCount, 3);
      expect(newInventory.getTotalQuantity(), 600);

      final filteredInventory = newInventory;
      expect(filteredInventory.itemCount, 3);
    });

    test('Inventory 统计信息', () {
      final inventory = Inventory.empty();

      final color1 = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final color2 = BeadColor(
        code: '002',
        name: '绿色',
        red: 0,
        green: 255,
        blue: 0,
      );
      final color3 = BeadColor(
        code: '003',
        name: '蓝色',
        red: 0,
        green: 0,
        blue: 255,
      );

      final items = [
        InventoryItem(
          id: 'item_1',
          beadColor: color1,
          quantity: 100,
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'item_2',
          beadColor: color2,
          quantity: 50,
          lastUpdated: DateTime.now(),
        ),
        InventoryItem(
          id: 'item_3',
          beadColor: color3,
          quantity: 200,
          lastUpdated: DateTime.now(),
        ),
      ];

      var newInventory = inventory;
      for (final item in items) {
        newInventory = newInventory.addItem(item);
      }

      expect(newInventory.itemCount, 3);
      expect(newInventory.getTotalQuantity(), 350);
      expect(newInventory.getUniqueColorCount(), 3);
    });

    test('Inventory 库存检查', () {
      final inventory = Inventory.empty();

      final color = BeadColor(
        code: '001',
        name: '红色',
        red: 255,
        green: 0,
        blue: 0,
      );
      final item = InventoryItem(
        id: 'item_1',
        beadColor: color,
        quantity: 100,
        lastUpdated: DateTime.now(),
      );
      final newInventory = inventory.addItem(item);

      expect(newInventory.hasSufficientQuantity(color.code, 50), true);
      expect(newInventory.hasSufficientQuantity(color.code, 150), false);
      expect(newInventory.isLowStock(color.code, 50), false);
      expect(newInventory.isLowStock(color.code, 150), true);
    });
  });
}
