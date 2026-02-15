import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/models.dart';
import 'storage_service.dart';

class DesignStorageService {
  static const String _designsDirName = 'designs';
  static const String _designsIndexFileName = 'designs_index.json';

  final StorageService _storageService;

  static final DesignStorageService _instance = DesignStorageService._internal();
  factory DesignStorageService() => _instance;
  DesignStorageService._internal() : _storageService = StorageService();

  DesignStorageService.withStorage(this._storageService);

  String get _designsPath => '${_storageService.appDocDir.path}/$_designsDirName';

  Future<Directory> _getDesignsDir() async {
    final dir = Directory(_designsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _saveDesignsIndex(List<String> designIds) async {
    final indexData = {
      'designIds': designIds,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.writeJson(_designsIndexFileName, indexData);
  }

  Future<List<String>> _loadDesignsIndex() async {
    final data = await _storageService.readJson(_designsIndexFileName);
    if (data == null) return [];
    return (data['designIds'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  Future<void> saveDesign(BeadDesign design) async {
    await _getDesignsDir();
    final fileName = '$_designsDirName/${design.id}.json';
    await _storageService.writeJson(fileName, design.toJson());

    final designIds = await _loadDesignsIndex();
    if (!designIds.contains(design.id)) {
      designIds.add(design.id);
      await _saveDesignsIndex(designIds);
    }
  }

  Future<BeadDesign?> loadDesign(String id) async {
    final fileName = '$_designsDirName/$id.json';
    final data = await _storageService.readJson(fileName);
    if (data == null) return null;
    return BeadDesign.fromJson(data);
  }

  Future<List<BeadDesign>> loadAllDesigns() async {
    final designIds = await _loadDesignsIndex();
    final designs = <BeadDesign>[];

    for (final id in designIds) {
      final design = await loadDesign(id);
      if (design != null) {
        designs.add(design);
      }
    }

    designs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return designs;
  }

  Future<bool> deleteDesign(String id) async {
    try {
      final fileName = '$_designsDirName/$id.json';
      await _storageService.deleteFile(fileName);

      final designIds = await _loadDesignsIndex();
      designIds.remove(id);
      await _saveDesignsIndex(designIds);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> designExists(String id) async {
    final fileName = '$_designsDirName/$id.json';
    return _storageService.fileExists(fileName);
  }

  Future<String?> exportDesignToJson(String id) async {
    final design = await loadDesign(id);
    if (design == null) return null;
    return design.toJson().toString();
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
        await file.writeAsString(design.toJson().toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<BeadDesign?> importDesignFromJson(String jsonContent) async {
    try {
      final data = Map<String, dynamic>.from(
        const JsonDecoder().convert(jsonContent) as Map,
      );
      return BeadDesign.fromJson(data);
    } catch (e) {
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
      return null;
    }
  }

  Future<void> saveImportedDesign(BeadDesign design) async {
    await saveDesign(design);
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
