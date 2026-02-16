import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'version_check_service.dart';

enum DownloadStatus { idle, downloading, paused, completed, error }

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double progress;
  final DownloadStatus status;
  final String? errorMessage;

  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.errorMessage,
  });

  String get formattedDownloadedSize {
    if (downloadedBytes < 1024) {
      return '$downloadedBytes B';
    } else if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedTotalSize {
    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  DownloadProgress _progress = const DownloadProgress(
    downloadedBytes: 0,
    totalBytes: 0,
    progress: 0,
    status: DownloadStatus.idle,
  );

  DownloadProgress get progress => _progress;

  String? _downloadPath;
  http.Client? _httpClient;
  bool _isPaused = false;
  bool _isCancelled = false;
  int _downloadedBytes = 0;
  File? _downloadFile;
  IOSink? _sink;

  Future<String> get downloadPath async {
    if (_downloadPath != null) return _downloadPath!;

    final tempDir = await getTemporaryDirectory();
    _downloadPath = '${tempDir.path}/updates';
    final dir = Directory(_downloadPath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _downloadPath!;
  }

  Future<void> downloadUpdate(
    ReleaseAsset asset, {
    Function(DownloadProgress)? onProgress,
  }) async {
    if (_progress.status == DownloadStatus.downloading) {
      return;
    }

    _isPaused = false;
    _isCancelled = false;
    _downloadedBytes = 0;

    _updateProgress(
      downloadedBytes: 0,
      totalBytes: asset.size,
      progress: 0,
      status: DownloadStatus.downloading,
    );

    try {
      final savePath = await downloadPath;
      final fileName = asset.name;
      _downloadFile = File('$savePath/$fileName');

      _sink = _downloadFile!.openWrite();

      _httpClient = http.Client();

      final request = http.Request('GET', Uri.parse(asset.browserDownloadUrl));
      final response = await _httpClient!.send(request);

      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? asset.size;

      await for (final chunk in response.stream) {
        if (_isCancelled) {
          await _cleanup();
          _updateProgress(
            downloadedBytes: 0,
            totalBytes: 0,
            progress: 0,
            status: DownloadStatus.idle,
          );
          return;
        }

        if (_isPaused) {
          await _waitForResume();
          if (_isCancelled) {
            await _cleanup();
            _updateProgress(
              downloadedBytes: 0,
              totalBytes: 0,
              progress: 0,
              status: DownloadStatus.idle,
            );
            return;
          }
        }

        _sink!.add(chunk);
        _downloadedBytes += chunk.length;

        final progressValue = contentLength > 0
            ? _downloadedBytes / contentLength
            : 0.0;

        _updateProgress(
          downloadedBytes: _downloadedBytes,
          totalBytes: contentLength,
          progress: progressValue,
          status: DownloadStatus.downloading,
        );

        onProgress?.call(_progress);
      }

      await _sink!.flush();
      await _sink!.close();
      _sink = null;

      _updateProgress(
        downloadedBytes: _downloadedBytes,
        totalBytes: contentLength,
        progress: 1.0,
        status: DownloadStatus.completed,
      );

      onProgress?.call(_progress);
    } catch (e) {
      debugPrint('Download error: $e');
      await _cleanup();
      _updateProgress(
        downloadedBytes: _downloadedBytes,
        totalBytes: 0,
        progress: 0,
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
      onProgress?.call(_progress);
    }
  }

  void pauseDownload() {
    if (_progress.status == DownloadStatus.downloading) {
      _isPaused = true;
      _updateProgress(
        downloadedBytes: _downloadedBytes,
        totalBytes: _progress.totalBytes,
        progress: _progress.progress,
        status: DownloadStatus.paused,
      );
    }
  }

  void resumeDownload() {
    if (_progress.status == DownloadStatus.paused) {
      _isPaused = false;
      _updateProgress(
        downloadedBytes: _downloadedBytes,
        totalBytes: _progress.totalBytes,
        progress: _progress.progress,
        status: DownloadStatus.downloading,
      );
    }
  }

  void cancelDownload() {
    _isCancelled = true;
    _isPaused = false;
  }

  Future<void> _waitForResume() async {
    while (_isPaused && !_isCancelled) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _cleanup() async {
    try {
      await _sink?.close();
      _sink = null;
      _httpClient?.close();
      _httpClient = null;

      if (_downloadFile != null && await _downloadFile!.exists()) {
        await _downloadFile!.delete();
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  void _updateProgress({
    required int downloadedBytes,
    required int totalBytes,
    required double progress,
    required DownloadStatus status,
    String? errorMessage,
  }) {
    _progress = DownloadProgress(
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      progress: progress,
      status: status,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  Future<String?> installUpdate() async {
    if (_progress.status != DownloadStatus.completed || _downloadFile == null) {
      return null;
    }

    try {
      final filePath = _downloadFile!.path;

      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('open', [filePath]);
        if (result.exitCode != 0) {
          throw Exception('无法打开文件: ${result.stderr}');
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('start', ['', filePath]);
        if (result.exitCode != 0) {
          throw Exception('无法打开文件: ${result.stderr}');
        }
      }

      return filePath;
    } catch (e) {
      debugPrint('Install error: $e');
      return null;
    }
  }

  Future<void> openDownloadFolder() async {
    try {
      final path = await downloadPath;
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      debugPrint('Open folder error: $e');
    }
  }

  Future<void> clearDownloads() async {
    try {
      final path = await downloadPath;
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      _updateProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        progress: 0,
        status: DownloadStatus.idle,
      );
    } catch (e) {
      debugPrint('Clear downloads error: $e');
    }
  }

  String? get downloadedFilePath => _downloadFile?.path;
}
