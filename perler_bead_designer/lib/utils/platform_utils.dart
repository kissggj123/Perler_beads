import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlatformUtils {
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get isDesktop => isWindows || isMacOS || isLinux;

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isWeb => kIsWeb;

  static String get ctrlKey {
    if (isMacOS) {
      return 'Cmd';
    }
    return 'Ctrl';
  }

  static String get ctrlKeyName {
    if (isMacOS) {
      return '⌘';
    }
    return 'Ctrl';
  }

  static String get modifierKeyName {
    if (isMacOS) {
      return '⌘';
    } else if (isWindows || isLinux) {
      return 'Ctrl';
    }
    return 'Ctrl';
  }

  static String get modifierKeyNameLong {
    if (isMacOS) {
      return 'Command';
    } else if (isWindows || isLinux) {
      return 'Ctrl';
    }
    return 'Ctrl';
  }

  static String get altKeyName {
    if (isMacOS) {
      return '⌥';
    } else if (isWindows) {
      return 'Alt';
    } else if (isLinux) {
      return 'Alt';
    }
    return 'Alt';
  }

  static String get shiftKeyName {
    if (isMacOS) {
      return '⇧';
    }
    return 'Shift';
  }

  static String get ctrlKeyNameRaw {
    if (isMacOS) {
      return '⌃';
    }
    return 'Ctrl';
  }

  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  static String pathJoin(List<String> parts) {
    if (kIsWeb) {
      return parts.join('/');
    }
    return parts.join(Platform.pathSeparator);
  }

  static String normalizePath(String path) {
    if (kIsWeb) {
      return path.replaceAll('\\', '/');
    }
    if (isWindows) {
      return path.replaceAll('/', '\\');
    } else {
      return path.replaceAll('\\', '/');
    }
  }

  static String get pathSeparator {
    if (kIsWeb) return '/';
    return Platform.pathSeparator;
  }

  static String get lineSeparator {
    if (kIsWeb) return '\n';
    if (isWindows) return '\r\n';
    return '\n';
  }

  static bool isFeatureSupported(String featureName) {
    if (kIsWeb) {
      return _getWebSupportedFeatures().contains(featureName);
    }

    if (isDesktop) {
      return _getDesktopSupportedFeatures().contains(featureName);
    }

    if (isMobile) {
      return _getMobileSupportedFeatures().contains(featureName);
    }

    return false;
  }

  static Set<String> _getDesktopSupportedFeatures() {
    return {
      'file_system',
      'keyboard_shortcuts',
      'window_controls',
      'system_tray',
      'drag_and_drop',
      'file_picker',
      'pdf_export',
      'image_export',
      'csv_export',
      'excel_export',
      'auto_update',
      'deep_linking',
      'native_menus',
      'multiple_windows',
    };
  }

  static Set<String> _getMobileSupportedFeatures() {
    return {
      'touch_input',
      'camera',
      'gallery',
      'share',
      'push_notifications',
      'file_picker',
      'pdf_export',
      'image_export',
    };
  }

  static Set<String> _getWebSupportedFeatures() {
    return {
      'keyboard_shortcuts',
      'file_picker',
      'pdf_export',
      'image_export',
      'share',
    };
  }

  static LogicalKeyboardKey get modifierKey {
    if (isMacOS) {
      return LogicalKeyboardKey.meta;
    }
    return LogicalKeyboardKey.control;
  }

  static bool isModifierPressed(Set<LogicalKeyboardKey> pressedKeys) {
    if (isMacOS) {
      return pressedKeys.contains(LogicalKeyboardKey.meta) ||
          pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
          pressedKeys.contains(LogicalKeyboardKey.metaRight);
    }
    return pressedKeys.contains(LogicalKeyboardKey.control) ||
        pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
  }

  static String getShortcutDisplay(String key) {
    return '$modifierKeyName$key';
  }

  static String getShortcutDisplayWithAlt(String key) {
    return '$modifierKeyName$altKeyName$key';
  }

  static String getShortcutDisplayFull(
    String key, {
    bool useShift = false,
    bool useAlt = false,
  }) {
    final parts = <String>[];
    parts.add(modifierKeyName);
    if (useShift) parts.add(shiftKeyName);
    if (useAlt) parts.add(altKeyName);
    parts.add(key);
    return parts.join('');
  }

  static String getShortcutTooltip(String action, String key) {
    return '$action ($ctrlKey+$key)';
  }

  static String? getDataDirectory() {
    if (kIsWeb) return null;
    return Platform.environment['APPDATA'] ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'];
  }

  static String? getHomeDirectory() {
    if (kIsWeb) return null;
    return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  }

  static String? getTempDirectory() {
    if (kIsWeb) return null;
    return Platform.environment['TEMP'] ?? Platform.environment['TMP'];
  }

  static Future<String?> get appDataPath async {
    if (kIsWeb) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      return appDir.path;
    } catch (e) {
      debugPrint('获取应用数据目录失败: $e');
      return getDataDirectory();
    }
  }

  static Future<String?> getAppSpecificDataPath(String appName) async {
    if (kIsWeb) return null;

    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final appPath = pathJoin([baseDir.path, appName]);
      final directory = Directory(appPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return appPath;
    } catch (e) {
      debugPrint('获取应用特定数据目录失败: $e');
      return null;
    }
  }

  static Future<bool> openInFileManager(String path) async {
    if (kIsWeb) return false;

    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (isMacOS) {
        final result = await Process.run('open', [path]);
        return result.exitCode == 0;
      } else if (isWindows) {
        final result = await Process.run('explorer', [path]);
        return result.exitCode == 0;
      } else if (isLinux) {
        final result = await Process.run('xdg-open', [path]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      debugPrint('打开文件管理器失败: $e');
      return false;
    }
  }

  static Future<bool> openFile(String filePath) async {
    if (kIsWeb) return false;

    try {
      if (isMacOS) {
        final result = await Process.run('open', [filePath]);
        return result.exitCode == 0;
      } else if (isWindows) {
        final result = await Process.run('start', ['', filePath]);
        return result.exitCode == 0;
      } else if (isLinux) {
        final result = await Process.run('xdg-open', [filePath]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      debugPrint('打开文件失败: $e');
      return false;
    }
  }

  static Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'isWeb': isWeb,
      'modifierKey': modifierKeyName,
      'ctrlKey': ctrlKey,
      'ctrlKeyName': ctrlKeyName,
      'pathSeparator': pathSeparator,
      'lineSeparator': lineSeparator
          .replaceAll('\r', '\\r')
          .replaceAll('\n', '\\n'),
    };
  }
}
