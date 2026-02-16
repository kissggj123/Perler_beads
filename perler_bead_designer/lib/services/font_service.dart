import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/platform_utils.dart';

enum FontLoadSource {
  system,
  cache,
  mirror,
  github,
  fallback,
}

class FontLoadResult {
  final pw.Font font;
  final FontLoadSource source;
  final String? sourcePath;

  FontLoadResult({
    required this.font,
    required this.source,
    this.sourcePath,
  });
}

class FontService {
  static final FontService _instance = FontService._internal();
  factory FontService() => _instance;
  FontService._internal();

  static const String _cacheFileName = 'chinese_font_cache.ttf';
  static const String _fontCacheDir = 'font_cache';

  pw.Font? _cachedFont;
  FontLoadSource? _cachedSource;
  String? _cachedSourcePath;

  static const Map<String, List<String>> _systemChineseFonts = {
    'macos': [
      '/System/Library/Fonts/PingFang.ttc',
      '/System/Library/Fonts/STHeiti Light.ttc',
      '/System/Library/Fonts/STHeiti Medium.ttc',
      '/Library/Fonts/Arial Unicode.ttf',
      '/System/Library/Fonts/Supplemental/Songti.ttc',
      '/System/Library/Fonts/Supplemental/Heiti.ttc',
    ],
    'windows': [
      'C:\\Windows\\Fonts\\msyh.ttc',
      'C:\\Windows\\Fonts\\msyhbd.ttc',
      'C:\\Windows\\Fonts\\simhei.ttf',
      'C:\\Windows\\Fonts\\simsun.ttc',
      'C:\\Windows\\Fonts\\simkai.ttf',
      'C:\\Windows\\Fonts\\simfang.ttf',
      'C:\\Windows\\Fonts\\STZHONGS.TTF',
      'C:\\Windows\\Fonts\\STFANGSO.TTF',
    ],
    'linux': [
      '/usr/share/fonts/truetype/wqy/wqy-microhei.ttc',
      '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc',
      '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
      '/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc',
      '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf',
      '/usr/share/fonts/opentype/arphic/uming.ttc',
      '/usr/share/fonts/truetype/arphic/uming.ttc',
    ],
  };

  static const List<FontMirrorSource> _mirrorSources = [
    FontMirrorSource(
      name: 'Gitee',
      baseUrl: 'https://gitee.com/mirrors/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese',
      fileName: 'NotoSansCJKsc-Regular.otf',
      priority: 1,
      isChinaMirror: true,
    ),
    FontMirrorSource(
      name: 'Aliyun',
      baseUrl: 'https://registry.npmmirror.com/noto-sans-cjk-sc/-/noto-sans-cjk-sc-1.0.0.tgz',
      fileName: 'package/dist/NotoSansCJKsc-Regular.otf',
      priority: 2,
      isChinaMirror: true,
    ),
    FontMirrorSource(
      name: 'GitHub',
      baseUrl: 'https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese',
      fileName: 'NotoSansCJKsc-Regular.otf',
      priority: 3,
      isChinaMirror: false,
    ),
    FontMirrorSource(
      name: 'GitHubMirror',
      baseUrl: 'https://ghproxy.com/https://github.com/googlefonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese',
      fileName: 'NotoSansCJKsc-Regular.otf',
      priority: 4,
      isChinaMirror: true,
    ),
  ];

  Future<FontLoadResult> loadChineseFont({bool forceReload = false}) async {
    if (!forceReload && _cachedFont != null) {
      return FontLoadResult(
        font: _cachedFont!,
        source: _cachedSource!,
        sourcePath: _cachedSourcePath,
      );
    }

    final systemResult = await _tryLoadSystemFont();
    if (systemResult != null) {
      _cachedFont = systemResult.font;
      _cachedSource = systemResult.source;
      _cachedSourcePath = systemResult.sourcePath;
      return systemResult;
    }

    final cacheResult = await _tryLoadCachedFont();
    if (cacheResult != null) {
      _cachedFont = cacheResult.font;
      _cachedSource = cacheResult.source;
      _cachedSourcePath = cacheResult.sourcePath;
      return cacheResult;
    }

    final downloadResult = await _downloadAndCacheFont();
    if (downloadResult != null) {
      _cachedFont = downloadResult.font;
      _cachedSource = downloadResult.source;
      _cachedSourcePath = downloadResult.sourcePath;
      return downloadResult;
    }

    _cachedFont = pw.Font.symbol();
    _cachedSource = FontLoadSource.fallback;
    _cachedSourcePath = null;

    return FontLoadResult(
      font: _cachedFont!,
      source: _cachedSource!,
      sourcePath: _cachedSourcePath,
    );
  }

  Future<FontLoadResult?> _tryLoadSystemFont() async {
    if (kIsWeb) return null;

    final platform = _getPlatformKey();
    final fontPaths = _systemChineseFonts[platform] ?? [];

    for (final fontPath in fontPaths) {
      try {
        final file = File(fontPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final font = pw.Font.ttf(ByteData.sublistView(bytes));
          debugPrint('成功加载系统字体: $fontPath');
          return FontLoadResult(
            font: font,
            source: FontLoadSource.system,
            sourcePath: fontPath,
          );
        }
      } catch (e) {
        debugPrint('加载系统字体失败 $fontPath: $e');
        continue;
      }
    }

    return null;
  }

  Future<FontLoadResult?> _tryLoadCachedFont() async {
    if (kIsWeb) return null;

    try {
      final cachePath = await _getFontCachePath();
      if (cachePath == null) return null;

      final cacheFile = File('$cachePath/$_cacheFileName');
      if (await cacheFile.exists()) {
        final bytes = await cacheFile.readAsBytes();
        final font = pw.Font.ttf(ByteData.sublistView(bytes));
        debugPrint('成功加载缓存字体: ${cacheFile.path}');
        return FontLoadResult(
          font: font,
          source: FontLoadSource.cache,
          sourcePath: cacheFile.path,
        );
      }
    } catch (e) {
      debugPrint('加载缓存字体失败: $e');
    }

    return null;
  }

  Future<FontLoadResult?> _downloadAndCacheFont() async {
    if (kIsWeb) {
      return await _downloadFromMirrors();
    }

    final sortedMirrors = List<FontMirrorSource>.from(_mirrorSources)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final isChinaNetwork = await _detectChinaNetwork();

    if (isChinaNetwork) {
      sortedMirrors.sort((a, b) {
        if (a.isChinaMirror && !b.isChinaMirror) return -1;
        if (!a.isChinaMirror && b.isChinaMirror) return 1;
        return a.priority.compareTo(b.priority);
      });
    }

    for (final mirror in sortedMirrors) {
      final result = await _tryDownloadFromMirror(mirror);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  Future<FontLoadResult?> _downloadFromMirrors() async {
    final sortedMirrors = List<FontMirrorSource>.from(_mirrorSources)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (final mirror in sortedMirrors) {
      final result = await _tryDownloadFromMirror(mirror);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  Future<FontLoadResult?> _tryDownloadFromMirror(FontMirrorSource mirror) async {
    final maxRetries = 3;
    final retryDelay = const Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('尝试从 ${mirror.name} 下载字体 (尝试 $attempt/$maxRetries)');

        final client = await _createHttpClient();
        final url = '${mirror.baseUrl}/${mirror.fileName}';

        final response = await client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final bytes = response.bodyBytes;

          if (!kIsWeb) {
            await _saveFontToCache(bytes);
          }

          final font = pw.Font.ttf(ByteData.sublistView(bytes));
          debugPrint('成功从 ${mirror.name} 下载字体');

          return FontLoadResult(
            font: font,
            source: mirror.isChinaMirror ? FontLoadSource.mirror : FontLoadSource.github,
            sourcePath: url,
          );
        }
      } catch (e) {
        debugPrint('从 ${mirror.name} 下载失败 (尝试 $attempt/$maxRetries): $e');

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
        }
      }
    }

    return null;
  }

  Future<http.Client> _createHttpClient() async {
    final proxyConfig = await _detectSystemProxy();

    if (proxyConfig != null) {
      debugPrint('检测到系统代理: ${proxyConfig.host}:${proxyConfig.port}');
    }

    return http.Client();
  }

  Future<ProxyConfig?> _detectSystemProxy() async {
    if (kIsWeb) return null;

    try {
      if (PlatformUtils.isWindows) {
        return await _detectWindowsProxy();
      } else if (PlatformUtils.isMacOS) {
        return await _detectMacOSProxy();
      } else if (PlatformUtils.isLinux) {
        return await _detectLinuxProxy();
      }
    } catch (e) {
      debugPrint('检测系统代理失败: $e');
    }

    return null;
  }

  Future<ProxyConfig?> _detectWindowsProxy() async {
    try {
      final result = await Process.run('netsh', ['winhttp', 'show', 'proxy']);
      final output = result.stdout.toString();

      final proxyMatch = RegExp(r'Proxy Server\s*:\s*(.+?):(\d+)').firstMatch(output);
      if (proxyMatch != null) {
        return ProxyConfig(
          host: proxyMatch.group(1)!,
          port: int.parse(proxyMatch.group(2)!),
        );
      }

      final envProxy = Platform.environment['HTTP_PROXY'] ?? Platform.environment['http_proxy'];
      if (envProxy != null) {
        return _parseProxyUrl(envProxy);
      }
    } catch (e) {
      debugPrint('检测 Windows 代理失败: $e');
    }

    return null;
  }

  Future<ProxyConfig?> _detectMacOSProxy() async {
    try {
      final result = await Process.run('networksetup', ['-getwebproxy', 'Wi-Fi']);
      final output = result.stdout.toString();

      final enabledMatch = RegExp(r'Enabled:\s*(\w+)').firstMatch(output);
      if (enabledMatch != null && enabledMatch.group(1) == 'Yes') {
        final hostMatch = RegExp(r'Server:\s*(.+)').firstMatch(output);
        final portMatch = RegExp(r'Port:\s*(\d+)').firstMatch(output);

        if (hostMatch != null && portMatch != null) {
          return ProxyConfig(
            host: hostMatch.group(1)!.trim(),
            port: int.parse(portMatch.group(1)!),
          );
        }
      }

      final envProxy = Platform.environment['HTTP_PROXY'] ?? Platform.environment['http_proxy'];
      if (envProxy != null) {
        return _parseProxyUrl(envProxy);
      }
    } catch (e) {
      debugPrint('检测 macOS 代理失败: $e');
    }

    return null;
  }

  Future<ProxyConfig?> _detectLinuxProxy() async {
    final envProxy = Platform.environment['HTTP_PROXY'] ??
        Platform.environment['http_proxy'] ??
        Platform.environment['ALL_PROXY'] ??
        Platform.environment['all_proxy'];

    if (envProxy != null) {
      return _parseProxyUrl(envProxy);
    }

    return null;
  }

  ProxyConfig? _parseProxyUrl(String proxyUrl) {
    try {
      final uri = Uri.tryParse(proxyUrl);
      if (uri != null && uri.host.isNotEmpty && uri.port > 0) {
        return ProxyConfig(host: uri.host, port: uri.port);
      }

      final match = RegExp(r'(?:https?://)?([^:]+):(\d+)').firstMatch(proxyUrl);
      if (match != null) {
        return ProxyConfig(
          host: match.group(1)!,
          port: int.parse(match.group(2)!),
        );
      }
    } catch (e) {
      debugPrint('解析代理 URL 失败: $e');
    }

    return null;
  }

  Future<bool> _detectChinaNetwork() async {
    if (kIsWeb) return false;

    try {
      final locale = Platform.localeName;
      if (locale.startsWith('zh_CN') || locale.startsWith('zh-Hans')) {
        return true;
      }

      final timezone = DateTime.now().timeZoneName;
      if (timezone == 'CST' || timezone == 'Asia/Shanghai') {
        return true;
      }
    } catch (e) {
      debugPrint('检测网络区域失败: $e');
    }

    return false;
  }

  Future<String?> _getFontCachePath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/$_fontCacheDir');

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      return cacheDir.path;
    } catch (e) {
      debugPrint('获取字体缓存目录失败: $e');
      return null;
    }
  }

  Future<void> _saveFontToCache(Uint8List bytes) async {
    try {
      final cachePath = await _getFontCachePath();
      if (cachePath == null) return;

      final cacheFile = File('$cachePath/$_cacheFileName');
      await cacheFile.writeAsBytes(bytes);
      debugPrint('字体已缓存到: ${cacheFile.path}');
    } catch (e) {
      debugPrint('保存字体缓存失败: $e');
    }
  }

  String _getPlatformKey() {
    if (PlatformUtils.isWindows) return 'windows';
    if (PlatformUtils.isMacOS) return 'macos';
    if (PlatformUtils.isLinux) return 'linux';
    return '';
  }

  Future<void> clearCache() async {
    if (kIsWeb) return;

    try {
      final cachePath = await _getFontCachePath();
      if (cachePath == null) return;

      final cacheDir = Directory(cachePath);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('字体缓存已清除');
      }

      _cachedFont = null;
      _cachedSource = null;
      _cachedSourcePath = null;
    } catch (e) {
      debugPrint('清除字体缓存失败: $e');
    }
  }

  FontLoadResult? get cachedResult {
    if (_cachedFont == null) return null;
    return FontLoadResult(
      font: _cachedFont!,
      source: _cachedSource!,
      sourcePath: _cachedSourcePath,
    );
  }

  bool get hasCachedFont => _cachedFont != null;
}

class FontMirrorSource {
  final String name;
  final String baseUrl;
  final String fileName;
  final int priority;
  final bool isChinaMirror;

  const FontMirrorSource({
    required this.name,
    required this.baseUrl,
    required this.fileName,
    required this.priority,
    required this.isChinaMirror,
  });
}

class ProxyConfig {
  final String host;
  final int port;

  const ProxyConfig({
    required this.host,
    required this.port,
  });

  String get proxyUrl => 'http://$host:$port';

  @override
  String toString() => 'ProxyConfig($host:$port)';
}
