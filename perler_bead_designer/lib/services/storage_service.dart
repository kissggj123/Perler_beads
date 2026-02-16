import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageServiceException implements Exception {
  final String message;
  final dynamic originalError;

  const StorageServiceException(this.message, {this.originalError});

  @override
  String toString() => 'StorageServiceException: $message';
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _appDocDir;
  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _appDocDir = await getApplicationDocumentsDirectory();
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    } catch (e) {
      debugPrint('StorageService 初始化失败: $e');
      rethrow;
    }
  }

  bool get isInitialized => _initialized;

  Directory get appDocDir {
    if (_appDocDir == null || !_initialized) {
      throw StorageServiceException(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _appDocDir!;
  }

  SharedPreferences get prefs {
    if (_prefs == null || !_initialized) {
      throw StorageServiceException(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  Future<File> _getFile(String fileName) async {
    final path = '${appDocDir.path}/$fileName';
    return File(path);
  }

  Future<bool> fileExists(String fileName) async {
    try {
      final file = await _getFile(fileName);
      return file.exists();
    } catch (e) {
      debugPrint('检查文件存在失败: $e');
      return false;
    }
  }

  Future<bool> writeJson(String fileName, Map<String, dynamic> data) async {
    try {
      final file = await _getFile(fileName);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('写入JSON文件失败: $e');
      return false;
    }
  }

  Future<bool> writeJsonList(
    String fileName,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final file = await _getFile(fileName);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('写入JSON列表文件失败: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> readJson(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('JSON文件格式错误: $fileName');
        return null;
      }
      return decoded;
    } catch (e) {
      debugPrint('读取JSON文件失败: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> readJsonList(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      if (content.isEmpty) return null;

      final decoded = jsonDecode(content);
      if (decoded is! List) {
        debugPrint('JSON列表文件格式错误: $fileName');
        return null;
      }
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('读取JSON列表文件失败: $e');
      return null;
    }
  }

  Future<bool> writeString(String fileName, String content) async {
    try {
      final file = await _getFile(fileName);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('写入字符串文件失败: $e');
      return false;
    }
  }

  Future<String?> readString(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      debugPrint('读取字符串文件失败: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String fileName) async {
    try {
      final file = await _getFile(fileName);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('删除文件失败: $e');
      return false;
    }
  }

  Future<bool> setPreference(String key, dynamic value) async {
    try {
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else {
        debugPrint('不支持的偏好设置类型: ${value.runtimeType}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('设置偏好失败: $e');
      return false;
    }
  }

  T? getPreference<T>(String key) {
    try {
      return prefs.get(key) as T?;
    } catch (e) {
      debugPrint('获取偏好失败: $e');
      return null;
    }
  }

  Future<bool> removePreference(String key) async {
    try {
      await prefs.remove(key);
      return true;
    } catch (e) {
      debugPrint('移除偏好失败: $e');
      return false;
    }
  }

  Future<String> getExportPath(String fileName) async {
    return '${appDocDir.path}/$fileName';
  }

  String get dataDirectoryPath {
    return appDocDir.path;
  }

  Future<bool> openDataDirectory() async {
    try {
      final path = dataDirectoryPath;
      if (Platform.isMacOS) {
        final result = await Process.run('open', [path]);
        return result.exitCode == 0;
      } else if (Platform.isWindows) {
        final result = await Process.run('explorer', [path]);
        return result.exitCode == 0;
      } else if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [path]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      debugPrint('打开数据目录失败: $e');
      return false;
    }
  }
}
