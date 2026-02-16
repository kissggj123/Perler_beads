
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReleaseInfo {
  final String version;
  final String tagName;
  final String releaseNotes;
  final String publishedAt;
  final String htmlUrl;
  final List<ReleaseAsset> assets;
  final bool isPrerelease;

  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.publishedAt,
    required this.htmlUrl,
    required this.assets,
    required this.isPrerelease,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    final assetsList = json['assets'] as List? ?? [];
    final assets = assetsList
        .map((asset) => ReleaseAsset.fromJson(asset as Map<String, dynamic>))
        .toList();

    return ReleaseInfo(
      version: version,
      tagName: tagName,
      releaseNotes: json['body'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      assets: assets,
      isPrerelease: json['prerelease'] as bool? ?? false,
    );
  }

  ReleaseAsset? getAssetForCurrentPlatform() {
    final platform = _getPlatformIdentifier();
    try {
      return assets.firstWhere(
        (asset) => asset.name.toLowerCase().contains(platform),
      );
    } catch (_) {
      return null;
    }
  }

  String _getPlatformIdentifier() {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macos';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'windows';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'linux';
    }
    return '';
  }

  String get formattedPublishedAt {
    try {
      final dateTime = DateTime.parse(publishedAt);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return publishedAt;
    }
  }
}

class ReleaseAsset {
  final String name;
  final String url;
  final String browserDownloadUrl;
  final int size;
  final String contentType;

  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.browserDownloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class VersionCheckResult {
  final bool hasUpdate;
  final ReleaseInfo? releaseInfo;
  final String? errorMessage;
  final bool isSkipped;

  const VersionCheckResult({
    required this.hasUpdate,
    this.releaseInfo,
    this.errorMessage,
    this.isSkipped = false,
  });
}

class VersionCheckService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/kissggj123/Perler_beads/releases/latest';
  static const String _skippedVersionKey = 'skipped_version';
  static const String _lastCheckTimeKey = 'last_version_check_time';
  static const String _autoCheckEnabledKey = 'auto_version_check_enabled';

  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('VersionCheckService not initialized');
    }
    return _prefs!;
  }

  Future<VersionCheckResult> checkForUpdate({
    String currentVersion = '2.1.0',
    bool forceCheck = false,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(_githubApiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'BunnyCC-PerlerBeadDesigner',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return VersionCheckResult(
          hasUpdate: false,
          errorMessage: '服务器返回错误: ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final releaseInfo = ReleaseInfo.fromJson(json);

      final hasUpdate = _compareVersions(currentVersion, releaseInfo.version);

      if (!forceCheck && hasUpdate) {
        final skippedVersion = prefs.getString(_skippedVersionKey);
        if (skippedVersion == releaseInfo.version) {
          return VersionCheckResult(
            hasUpdate: true,
            releaseInfo: releaseInfo,
            isSkipped: true,
          );
        }
      }

      await _updateLastCheckTime();

      return VersionCheckResult(
        hasUpdate: hasUpdate,
        releaseInfo: releaseInfo,
      );
    } catch (e) {
      debugPrint('Version check error: $e');
      return VersionCheckResult(
        hasUpdate: false,
        errorMessage: '检查更新失败: $e',
      );
    }
  }

  bool _compareVersions(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      final maxLength =
          currentParts.length > latestParts.length
              ? currentParts.length
              : latestParts.length;

      for (var i = 0; i < maxLength; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) {
          return true;
        } else if (latestPart < currentPart) {
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false;
    }
  }

  Future<void> skipVersion(String version) async {
    await prefs.setString(_skippedVersionKey, version);
  }

  Future<void> clearSkippedVersion() async {
    await prefs.remove(_skippedVersionKey);
  }

  String? getSkippedVersion() {
    return prefs.getString(_skippedVersionKey);
  }

  Future<void> _updateLastCheckTime() async {
    await prefs.setString(
      _lastCheckTimeKey,
      DateTime.now().toIso8601String(),
    );
  }

  DateTime? getLastCheckTime() {
    final timeString = prefs.getString(_lastCheckTimeKey);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (_) {
      return null;
    }
  }

  bool shouldAutoCheck() {
    return prefs.getBool(_autoCheckEnabledKey) ?? true;
  }

  Future<void> setAutoCheckEnabled(bool enabled) async {
    await prefs.setBool(_autoCheckEnabledKey, enabled);
  }

  bool shouldCheckOnStartup() {
    final lastCheck = getLastCheckTime();
    if (lastCheck == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastCheck);

    return difference.inHours >= 24;
  }

  String formatReleaseNotes(String notes) {
    var formatted = notes;

    formatted = formatted.replaceAllMapped(
      RegExp(r'## (.+)'),
      (match) => '\n【${match.group(1)}】\n',
    );

    formatted = formatted.replaceAllMapped(
      RegExp(r'### (.+)'),
      (match) => '\n■ ${match.group(1)}\n',
    );

    formatted = formatted.replaceAll('- ', '• ');
    formatted = formatted.replaceAll('* ', '• ');
    formatted = formatted.replaceAll(RegExp(r'\*\*(.+?)\*\*'), '【\\1】');

    while (formatted.contains('\n\n\n')) {
      formatted = formatted.replaceAll('\n\n\n', '\n\n');
    }

    return formatted.trim();
  }
}
