import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class InventoryStorageService {
  static const String _inventoryFileName = 'inventory.json';
  static final InventoryStorageService _instance =
      InventoryStorageService._internal();

  static InventoryStorageService get instance => _instance;

  InventoryStorageService._internal();

  factory InventoryStorageService() => _instance;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_inventoryFileName');
  }

  Future<void> saveInventory(Inventory inventory) async {
    final file = await _localFile;
    final json = inventory.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  Future<Inventory?> loadInventory() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return null;
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        return null;
      }
      final json = jsonDecode(content) as Map<String, dynamic>;
      return Inventory.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<String> exportToCsv() async {
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
      return false;
    }
  }

  Future<Inventory?> importFromCsv(String csvContent) async {
    try {
      final rows = const CsvToListConverter().convert(csvContent);
      if (rows.isEmpty) return null;

      final items = <InventoryItem>[];
      bool isFirstRow = true;

      for (final row in rows) {
        if (isFirstRow) {
          isFirstRow = false;
          continue;
        }

        if (row.length >= 5) {
          final color = BeadColor(
            code: row[1].toString(),
            name: row[2].toString(),
            red: row.length > 5
                ? (int.tryParse(row[5].toString()) ?? 128)
                : 128,
            green: row.length > 6
                ? (int.tryParse(row[6].toString()) ?? 128)
                : 128,
            blue: row.length > 7
                ? (int.tryParse(row[7].toString()) ?? 128)
                : 128,
            brand: BeadBrand.values.firstWhere(
              (b) => b.name == row[3].toString(),
              orElse: () => BeadBrand.generic,
            ),
            category: row.length > 8 ? row[8].toString() : null,
          );
          final quantity = int.tryParse(row[4].toString()) ?? 0;
          items.add(
            InventoryItem(
              id: row[0].toString().isEmpty
                  ? 'import_${DateTime.now().millisecondsSinceEpoch}_${items.length}'
                  : row[0].toString(),
              beadColor: color,
              quantity: quantity,
              lastUpdated: row.length > 9
                  ? DateTime.tryParse(row[9].toString()) ?? DateTime.now()
                  : DateTime.now(),
            ),
          );
        }
      }

      return Inventory(items: items, lastUpdated: DateTime.now());
    } catch (e) {
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
      return null;
    }
  }

  Future<Inventory?> importFromJson(String jsonContent) async {
    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      return Inventory.fromJson(data);
    } catch (e) {
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
      return false;
    }
  }

  Future<void> clearInventory() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
