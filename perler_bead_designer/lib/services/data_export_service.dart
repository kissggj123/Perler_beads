import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/models.dart';
import 'design_storage_service.dart';
import 'inventory_storage_service.dart';

class DataExportService {
  static const String _currentDataVersion = '1.0.0';
  static const String _backupFileName = 'bunnycc_perler_backup';

  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final DesignStorageService _designStorage = DesignStorageService();
  final InventoryStorageService _inventoryStorage = InventoryStorageService();

  Future<Map<String, dynamic>> exportAllDataToJson({
    void Function(int current, int total, String status)? onProgress,
  }) async {
    onProgress?.call(0, 100, '准备导出...');

    final data = <String, dynamic>{
      'version': _currentDataVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'appName': '兔可可的拼豆世界',
      'data': <String, dynamic>{},
    };

    onProgress?.call(10, 100, '加载设计数据...');
    final designs = await _designStorage.loadAllDesigns();
    onProgress?.call(30, 100, '加载库存数据...');
    final inventory = await _inventoryStorage.loadInventory();

    onProgress?.call(50, 100, '序列化设计数据...');
    final designsData = <Map<String, dynamic>>[];
    for (var i = 0; i < designs.length; i++) {
      designsData.add(designs[i].toJson());
      onProgress?.call(
        50 + (i / designs.length * 20).toInt(),
        100,
        '处理设计 ${i + 1}/${designs.length}',
      );
    }

    onProgress?.call(70, 100, '序列化库存数据...');
    final inventoryData = inventory?.toJson();

    data['data'] = {
      'designs': designsData,
      'inventory': inventoryData,
      'designCount': designs.length,
      'inventoryItemCount': inventory?.items.length ?? 0,
    };

    onProgress?.call(100, 100, '导出完成');
    return data;
  }

  Future<bool> exportAllDataToFile({
    void Function(int current, int total, String status)? onProgress,
  }) async {
    try {
      final data = await exportAllDataToJson(onProgress: onProgress);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final defaultFileName = '${_backupFileName}_$timestamp.json';

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出所有数据',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        final jsonString = const JsonEncoder.withIndent('  ').convert(data);
        await file.writeAsString(jsonString);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<ImportResult> importDataFromFile({
    void Function(int current, int total, String status)? onProgress,
    bool overwriteExisting = false,
  }) async {
    try {
      onProgress?.call(0, 100, '选择文件...');

      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择备份文件',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return ImportResult.cancelled();
      }

      final file = File(result.files.single.path!);
      return await importDataFromContent(
        await file.readAsString(),
        onProgress: onProgress,
        overwriteExisting: overwriteExisting,
      );
    } catch (e) {
      return ImportResult.failed('读取文件失败: $e');
    }
  }

  Future<ImportResult> importDataFromContent(
    String jsonContent, {
    void Function(int current, int total, String status)? onProgress,
    bool overwriteExisting = false,
  }) async {
    try {
      onProgress?.call(10, 100, '解析数据...');

      final Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(
          const JsonDecoder().convert(jsonContent) as Map,
        );
      } catch (e) {
        return ImportResult.failed('无效的 JSON 格式');
      }

      final version = data['version'] as String?;
      if (!_isVersionSupported(version)) {
        return ImportResult.failed('不支持的数据格式版本: $version');
      }

      final dataSection = data['data'] as Map<String, dynamic>?;
      if (dataSection == null) {
        return ImportResult.failed('备份数据格式无效');
      }

      int importedDesigns = 0;
      int importedInventoryItems = 0;
      int skippedDesigns = 0;

      final designsData = dataSection['designs'] as List<dynamic>?;
      if (designsData != null && designsData.isNotEmpty) {
        onProgress?.call(30, 100, '导入设计数据...');

        for (var i = 0; i < designsData.length; i++) {
          final designJson = _migrateDesignData(
            Map<String, dynamic>.from(designsData[i]),
            version,
          );

          try {
            final design = BeadDesign.fromJson(designJson);
            final exists = await _designStorage.designExists(design.id);

            if (exists && !overwriteExisting) {
              final newId =
                  '${design.id}_imported_${DateTime.now().millisecondsSinceEpoch}';
              final newDesign = design.copyWith(
                id: newId,
                name: '${design.name} (导入)',
              );
              await _designStorage.saveImportedDesign(newDesign);
              skippedDesigns++;
            } else {
              await _designStorage.saveImportedDesign(design);
            }
            importedDesigns++;
          } catch (e) {
            continue;
          }

          onProgress?.call(
            30 + (i / designsData.length * 40).toInt(),
            100,
            '导入设计 ${i + 1}/${designsData.length}',
          );
        }
      }

      final inventoryData = dataSection['inventory'] as Map<String, dynamic>?;
      if (inventoryData != null) {
        onProgress?.call(75, 100, '导入库存数据...');

        try {
          final migratedInventoryData = _migrateInventoryData(
            inventoryData,
            version,
          );
          final inventory = Inventory.fromJson(migratedInventoryData);

          if (overwriteExisting) {
            await _inventoryStorage.saveInventory(inventory);
          } else {
            final existingInventory = await _inventoryStorage.loadInventory();
            if (existingInventory != null) {
              final mergedInventory = _mergeInventories(
                existingInventory,
                inventory,
              );
              await _inventoryStorage.saveInventory(mergedInventory);
            } else {
              await _inventoryStorage.saveInventory(inventory);
            }
          }
          importedInventoryItems = inventory.items.length;
        } catch (e) {
          return ImportResult.failed('导入库存数据失败: $e');
        }
      }

      onProgress?.call(100, 100, '导入完成');

      return ImportResult.success(
        importedDesigns: importedDesigns,
        importedInventoryItems: importedInventoryItems,
        skippedDesigns: skippedDesigns,
      );
    } catch (e) {
      return ImportResult.failed('导入失败: $e');
    }
  }

  bool _isVersionSupported(String? version) {
    if (version == null) return true;

    final supportedVersions = ['1.0.0'];
    return supportedVersions.contains(version);
  }

  Map<String, dynamic> _migrateDesignData(
    Map<String, dynamic> data,
    String? fromVersion,
  ) {
    if (fromVersion == null) {
      return _applyDefaultDesignFields(data);
    }

    switch (fromVersion) {
      case '1.0.0':
        return data;
      default:
        return _applyDefaultDesignFields(data);
    }
  }

  Map<String, dynamic> _applyDefaultDesignFields(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    migrated['id'] ??= 'imported_${DateTime.now().millisecondsSinceEpoch}';
    migrated['name'] ??= '未命名设计';
    migrated['width'] ??= 29;
    migrated['height'] ??= 29;
    migrated['grid'] ??= List.generate(
      migrated['height'] as int? ?? 29,
      (_) => List.filled(migrated['width'] as int? ?? 29, null),
    );
    migrated['createdAt'] ??= DateTime.now().toIso8601String();
    migrated['updatedAt'] ??= DateTime.now().toIso8601String();

    return migrated;
  }

  Map<String, dynamic> _migrateInventoryData(
    Map<String, dynamic> data,
    String? fromVersion,
  ) {
    if (fromVersion == null) {
      return _applyDefaultInventoryFields(data);
    }

    switch (fromVersion) {
      case '1.0.0':
        return data;
      default:
        return _applyDefaultInventoryFields(data);
    }
  }

  Map<String, dynamic> _applyDefaultInventoryFields(Map<String, dynamic> data) {
    final migrated = Map<String, dynamic>.from(data);

    migrated['items'] ??= [];
    migrated['lastUpdated'] ??= DateTime.now().toIso8601String();

    return migrated;
  }

  Inventory _mergeInventories(Inventory existing, Inventory imported) {
    final existingItems = {
      for (var item in existing.items) item.beadColor.code: item,
    };

    for (final importedItem in imported.items) {
      final code = importedItem.beadColor.code;
      if (existingItems.containsKey(code)) {
        final existingItem = existingItems[code]!;
        existingItems[code] = InventoryItem(
          id: existingItem.id,
          beadColor: importedItem.beadColor,
          quantity: existingItem.quantity + importedItem.quantity,
          lastUpdated: DateTime.now(),
        );
      } else {
        existingItems[code] = importedItem;
      }
    }

    return Inventory(
      items: existingItems.values.toList(),
      lastUpdated: DateTime.now(),
    );
  }

  Future<BackupInfo?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = Map<String, dynamic>.from(
        const JsonDecoder().convert(content) as Map,
      );

      final dataSection = data['data'] as Map<String, dynamic>?;

      return BackupInfo(
        version: data['version'] as String? ?? '未知',
        exportDate: data['exportDate'] != null
            ? DateTime.tryParse(data['exportDate'] as String)
            : null,
        appName: data['appName'] as String? ?? '未知应用',
        designCount: dataSection?['designCount'] as int? ?? 0,
        inventoryItemCount: dataSection?['inventoryItemCount'] as int? ?? 0,
      );
    } catch (e) {
      return null;
    }
  }
}

class ImportResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final int importedDesigns;
  final int importedInventoryItems;
  final int skippedDesigns;

  const ImportResult._({
    required this.success,
    this.cancelled = false,
    this.errorMessage,
    this.importedDesigns = 0,
    this.importedInventoryItems = 0,
    this.skippedDesigns = 0,
  });

  factory ImportResult.success({
    int importedDesigns = 0,
    int importedInventoryItems = 0,
    int skippedDesigns = 0,
  }) {
    return ImportResult._(
      success: true,
      importedDesigns: importedDesigns,
      importedInventoryItems: importedInventoryItems,
      skippedDesigns: skippedDesigns,
    );
  }

  factory ImportResult.failed(String message) {
    return ImportResult._(success: false, errorMessage: message);
  }

  factory ImportResult.cancelled() {
    return const ImportResult._(success: false, cancelled: true);
  }

  String get summary {
    if (cancelled) return '导入已取消';
    if (!success) return errorMessage ?? '导入失败';

    final parts = <String>[];
    if (importedDesigns > 0) {
      parts.add('$importedDesigns 个设计');
    }
    if (importedInventoryItems > 0) {
      parts.add('$importedInventoryItems 个库存项');
    }
    if (skippedDesigns > 0) {
      parts.add('$skippedDesigns 个设计已重命名');
    }

    return parts.isEmpty ? '导入成功' : '成功导入: ${parts.join(', ')}';
  }
}

class BackupInfo {
  final String version;
  final DateTime? exportDate;
  final String appName;
  final int designCount;
  final int inventoryItemCount;

  const BackupInfo({
    required this.version,
    this.exportDate,
    required this.appName,
    required this.designCount,
    required this.inventoryItemCount,
  });

  String get formattedDate {
    if (exportDate == null) return '未知';
    return '${exportDate!.year}-${exportDate!.month.toString().padLeft(2, '0')}-${exportDate!.day.toString().padLeft(2, '0')} '
        '${exportDate!.hour.toString().padLeft(2, '0')}:${exportDate!.minute.toString().padLeft(2, '0')}';
  }

  String get summary {
    return '版本: $version\n'
        '导出时间: $formattedDate\n'
        '设计数量: $designCount\n'
        '库存项数量: $inventoryItemCount';
  }
}
