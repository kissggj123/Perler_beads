import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class InventoryStorageService {
  static const String _inventoryFileName = 'inventory.json';
  static final InventoryStorageService _instance =
      InventoryStorageService._internal();

  static InventoryStorageService get instance => _instance;

  InventoryStorageService._internal();

  factory InventoryStorageService() => _instance;

  Future<String?> get _localPath async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      debugPrint('获取本地路径失败: $e');
      return null;
    }
  }

  Future<File?> get _localFile async {
    final path = await _localPath;
    if (path == null) return null;
    return File('$path/$_inventoryFileName');
  }

  Future<bool> saveInventory(Inventory inventory) async {
    try {
      final file = await _localFile;
      if (file == null) {
        debugPrint('无法获取库存文件路径');
        return false;
      }

      final json = inventory.toJson();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );
      return true;
    } catch (e) {
      debugPrint('保存库存失败: $e');
      return false;
    }
  }

  Future<Inventory?> loadInventory() async {
    try {
      final file = await _localFile;
      if (file == null) return null;

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('库存文件格式错误');
        return null;
      }

      return Inventory.fromJson(decoded);
    } catch (e) {
      debugPrint('加载库存失败: $e');
      return null;
    }
  }

  Future<String> exportToCsv() async {
    try {
      final inventory = await loadInventory();
      if (inventory == null || inventory.items.isEmpty) {
        return '';
      }

      final rows = <List<dynamic>>[
        ['ID', '颜色代码', '颜色名称', '品牌', '数量', '红色', '绿色', '蓝色', '分类', '最后更新'],
      ];

      for (final item in inventory.items) {
        rows.add([
          item.id,
          item.beadColor.code,
          item.beadColor.name,
          item.beadColor.brand.name,
          item.quantity,
          item.beadColor.red,
          item.beadColor.green,
          item.beadColor.blue,
          item.beadColor.category ?? '',
          item.lastUpdated.toIso8601String(),
        ]);
      }

      return const ListToCsvConverter().convert(rows);
    } catch (e) {
      debugPrint('导出CSV失败: $e');
      return '';
    }
  }

  Future<bool> exportToCsvFile() async {
    try {
      final csv = await exportToCsv();
      if (csv.isEmpty) return false;

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出库存为CSV',
        fileName:
            'inventory_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(csv);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('导出CSV文件失败: $e');
      return false;
    }
  }

  Future<Inventory?> importFromCsv(String csvContent) async {
    try {
      if (csvContent.isEmpty) return null;

      final rows = const CsvToListConverter().convert(csvContent);
      if (rows.isEmpty) return null;

      final items = <InventoryItem>[];
      bool isFirstRow = true;

      for (final row in rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }

        if (row is! List || row.length < 5) continue;

        try {
          final color = BeadColor(
            code: row[1]?.toString() ?? '',
            name: row[2]?.toString() ?? '',
            red: row.length > 5
                ? (int.tryParse(row[5]?.toString() ?? '') ?? 128)
                : 128,
            green: row.length > 6
                ? (int.tryParse(row[6]?.toString() ?? '') ?? 128)
                : 128,
            blue: row.length > 7
                ? (int.tryParse(row[7]?.toString() ?? '') ?? 128)
                : 128,
            brand: BeadBrand.values.firstWhere(
              (b) => b.name == row[3]?.toString(),
              orElse: () => BeadBrand.generic,
            ),
            category: row.length > 8 ? row[8]?.toString() : null,
          );
          final quantity = int.tryParse(row[4]?.toString() ?? '') ?? 0;
          items.add(
            InventoryItem(
              id: row[0]?.toString().isEmpty ?? true
                  ? 'import_${DateTime.now().millisecondsSinceEpoch}_${items.length}'
                  : row[0].toString(),
              beadColor: color,
              quantity: quantity,
              lastUpdated: row.length > 9
                  ? DateTime.tryParse(row[9]?.toString() ?? '') ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('解析CSV行失败: $e');
          continue;
        }
      }

      return Inventory(items: items, lastUpdated: DateTime.now());
    } catch (e) {
      debugPrint('从CSV导入失败: $e');
      return null;
    }
  }

  Future<Inventory?> importFromCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择CSV文件',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        return await importFromCsv(content);
      }
      return null;
    } catch (e) {
      debugPrint('从CSV文件导入失败: $e');
      return null;
    }
  }

  Future<Inventory?> importFromJson(String jsonContent) async {
    try {
      if (jsonContent.isEmpty) return null;

      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('JSON格式错误');
        return null;
      }

      return Inventory.fromJson(decoded);
    } catch (e) {
      debugPrint('从JSON导入失败: $e');
      return null;
    }
  }

  Future<Inventory?> importFromJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择JSON文件',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        return await importFromJson(content);
      }
      return null;
    } catch (e) {
      debugPrint('从JSON文件导入失败: $e');
      return null;
    }
  }

  Future<bool> exportToJsonFile() async {
    try {
      final inventory = await loadInventory();
      if (inventory == null) return false;

      final json = const JsonEncoder.withIndent(
        '  ',
      ).convert(inventory.toJson());

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出库存为JSON',
        fileName:
            'inventory_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(json);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('导出JSON文件失败: $e');
      return false;
    }
  }

  Future<bool> clearInventory() async {
    try {
      final file = await _localFile;
      if (file == null) return false;

      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('清除库存失败: $e');
      return false;
    }
  }
}
