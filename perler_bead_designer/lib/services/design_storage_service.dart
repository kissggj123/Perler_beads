import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'storage_service.dart';

class DesignStorageService {
  static const String _designsDirName = 'designs';
  static const String _designsIndexFileName = 'designs_index.json';

  final StorageService _storageService;

  static final DesignStorageService _instance =
      DesignStorageService._internal();
  factory DesignStorageService() => _instance;
  DesignStorageService._internal() : _storageService = StorageService();

  DesignStorageService.withStorage(this._storageService);

  String get _designsPath {
    try {
      return '${_storageService.appDocDir.path}/$_designsDirName';
    } catch (e) {
      debugPrint('获取设计路径失败: $e');
      return '';
    }
  }

  Future<Directory?> _getDesignsDir() async {
    try {
      final path = _designsPath;
      if (path.isEmpty) return null;

      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      debugPrint('创建设计目录失败: $e');
      return null;
    }
  }

  Future<void> _saveDesignsIndex(List<String> designIds) async {
    final indexData = {
      'designIds': designIds,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.writeJson(_designsIndexFileName, indexData);
  }

  Future<List<String>> _loadDesignsIndex() async {
    try {
      final data = await _storageService.readJson(_designsIndexFileName);
      if (data == null) return [];
      final designIds = data['designIds'];
      if (designIds is! List) return [];
      return designIds.cast<String>();
    } catch (e) {
      debugPrint('加载设计索引失败: $e');
      return [];
    }
  }

  Future<bool> saveDesign(BeadDesign design) async {
    try {
      final dir = await _getDesignsDir();
      if (dir == null) {
        debugPrint('无法获取设计目录');
        return false;
      }

      final fileName = '$_designsDirName/${design.id}.json';
      final success = await _storageService.writeJson(
        fileName,
        design.toJson(),
      );
      if (!success) {
        debugPrint('保存设计文件失败: ${design.id}');
        return false;
      }

      final designIds = await _loadDesignsIndex();
      if (!designIds.contains(design.id)) {
        designIds.add(design.id);
        await _saveDesignsIndex(designIds);
      }
      return true;
    } catch (e) {
      debugPrint('保存设计失败: $e');
      return false;
    }
  }

  Future<BeadDesign?> loadDesign(String id) async {
    try {
      if (id.isEmpty) return null;

      final fileName = '$_designsDirName/$id.json';
      final data = await _storageService.readJson(fileName);
      if (data == null) return null;

      return BeadDesign.fromJson(data);
    } catch (e) {
      debugPrint('加载设计失败: $e');
      return null;
    }
  }

  Future<List<BeadDesign>> loadAllDesigns() async {
    final designIds = await _loadDesignsIndex();
    final designs = <BeadDesign>[];

    for (final id in designIds) {
      try {
        final design = await loadDesign(id);
        if (design != null) {
          designs.add(design);
        }
      } catch (e) {
        debugPrint('加载设计 $id 失败: $e');
      }
    }

    try {
      designs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('排序设计失败: $e');
    }
    return designs;
  }

  Future<bool> deleteDesign(String id) async {
    try {
      if (id.isEmpty) return false;

      final fileName = '$_designsDirName/$id.json';
      await _storageService.deleteFile(fileName);

      final designIds = await _loadDesignsIndex();
      designIds.remove(id);
      await _saveDesignsIndex(designIds);

      return true;
    } catch (e) {
      debugPrint('删除设计失败: $e');
      return false;
    }
  }

  Future<bool> designExists(String id) async {
    try {
      if (id.isEmpty) return false;
      final fileName = '$_designsDirName/$id.json';
      return _storageService.fileExists(fileName);
    } catch (e) {
      debugPrint('检查设计存在失败: $e');
      return false;
    }
  }

  Future<String?> exportDesignToJson(String id) async {
    try {
      final design = await loadDesign(id);
      if (design == null) return null;
      return const JsonEncoder.withIndent('  ').convert(design.toJson());
    } catch (e) {
      debugPrint('导出设计JSON失败: $e');
      return null;
    }
  }

  Future<bool> exportDesignToJsonFile(String id) async {
    try {
      final design = await loadDesign(id);
      if (design == null) return false;

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出设计为JSON',
        fileName: '${design.name.replaceAll(RegExp(r'[^\w\s-]'), '_')}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        final jsonStr = const JsonEncoder.withIndent(
          '  ',
        ).convert(design.toJson());
        await file.writeAsString(jsonStr);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('导出设计到文件失败: $e');
      return false;
    }
  }

  Future<BeadDesign?> importDesignFromJson(String jsonContent) async {
    try {
      if (jsonContent.isEmpty) return null;

      final decoded = const JsonDecoder().convert(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('JSON格式错误');
        return null;
      }

      return BeadDesign.fromJson(decoded);
    } catch (e) {
      debugPrint('从JSON导入设计失败: $e');
      return null;
    }
  }

  Future<BeadDesign?> importDesignFromJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择设计JSON文件',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        return await importDesignFromJson(content);
      }
      return null;
    } catch (e) {
      debugPrint('从文件导入设计失败: $e');
      return null;
    }
  }

  Future<bool> saveImportedDesign(BeadDesign design) async {
    return await saveDesign(design);
  }

  Future<int> getDesignCount() async {
    final designIds = await _loadDesignsIndex();
    return designIds.length;
  }

  Future<void> clearAllDesigns() async {
    final designIds = await _loadDesignsIndex();
    for (final id in designIds) {
      await deleteDesign(id);
    }
  }
}
