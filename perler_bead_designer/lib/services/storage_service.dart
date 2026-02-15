import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _appDocDir;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _appDocDir = await getApplicationDocumentsDirectory();
    _prefs = await SharedPreferences.getInstance();
  }

  Directory get appDocDir {
    if (_appDocDir == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _appDocDir!;
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  Future<File> _getFile(String fileName) async {
    final path = '${appDocDir.path}/$fileName';
    return File(path);
  }

  Future<bool> fileExists(String fileName) async {
    final file = await _getFile(fileName);
    return file.exists();
  }

  Future<void> writeJson(String fileName, Map<String, dynamic> data) async {
    final file = await _getFile(fileName);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
  }

  Future<void> writeJsonList(String fileName, List<Map<String, dynamic>> data) async {
    final file = await _getFile(fileName);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
  }

  Future<Map<String, dynamic>?> readJson(String fileName) async {
    final file = await _getFile(fileName);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.isEmpty) return null;

    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>?> readJsonList(String fileName) async {
    final file = await _getFile(fileName);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.isEmpty) return null;

    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return null;
  }

  Future<void> writeString(String fileName, String content) async {
    final file = await _getFile(fileName);
    await file.writeAsString(content);
  }

  Future<String?> readString(String fileName) async {
    final file = await _getFile(fileName);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  Future<void> deleteFile(String fileName) async {
    final file = await _getFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> setPreference(String key, dynamic value) async {
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
    }
  }

  T? getPreference<T>(String key) {
    return prefs.get(key) as T?;
  }

  Future<void> removePreference(String key) async {
    await prefs.remove(key);
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
      return false;
    }
  }
}
