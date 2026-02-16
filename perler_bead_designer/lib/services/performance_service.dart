import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GpuBackend { auto, metal, vulkan, directX, openGL, software }

enum PerformanceLevel { low, medium, high, ultra }

enum FpsLimit {
  fps30(30, '30 FPS'),
  fps60(60, '60 FPS'),
  fps120(120, '120 FPS'),
  unlimited(0, '无限制');

  final int value;
  final String label;
  const FpsLimit(this.value, this.label);
}

enum CacheSize {
  small(50, '小 (50 MB)'),
  medium(100, '中 (100 MB)'),
  large(200, '大 (200 MB)'),
  unlimited(-1, '无限制');

  final int valueMB;
  final String label;
  const CacheSize(this.valueMB, this.label);

  int get maxCacheBytes => valueMB > 0 ? valueMB * 1024 * 1024 : -1;
}

class PerformanceConfig {
  final GpuBackend gpuBackend;
  final PerformanceLevel performanceLevel;
  final bool enableGpuAcceleration;
  final bool enableVsync;
  final int targetFrameRate;
  final bool enableMultithreading;
  final bool enableCacheOptimization;
  final FpsLimit fpsLimit;
  final CacheSize cacheSize;

  const PerformanceConfig({
    this.gpuBackend = GpuBackend.auto,
    this.performanceLevel = PerformanceLevel.high,
    this.enableGpuAcceleration = true,
    this.enableVsync = true,
    this.targetFrameRate = 60,
    this.enableMultithreading = true,
    this.enableCacheOptimization = true,
    this.fpsLimit = FpsLimit.fps60,
    this.cacheSize = CacheSize.medium,
  });

  int get effectiveFrameRate =>
      fpsLimit == FpsLimit.unlimited ? targetFrameRate : fpsLimit.value;

  PerformanceConfig copyWith({
    GpuBackend? gpuBackend,
    PerformanceLevel? performanceLevel,
    bool? enableGpuAcceleration,
    bool? enableVsync,
    int? targetFrameRate,
    bool? enableMultithreading,
    bool? enableCacheOptimization,
    FpsLimit? fpsLimit,
    CacheSize? cacheSize,
  }) {
    return PerformanceConfig(
      gpuBackend: gpuBackend ?? this.gpuBackend,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      enableGpuAcceleration:
          enableGpuAcceleration ?? this.enableGpuAcceleration,
      enableVsync: enableVsync ?? this.enableVsync,
      targetFrameRate: targetFrameRate ?? this.targetFrameRate,
      enableMultithreading: enableMultithreading ?? this.enableMultithreading,
      enableCacheOptimization:
          enableCacheOptimization ?? this.enableCacheOptimization,
      fpsLimit: fpsLimit ?? this.fpsLimit,
      cacheSize: cacheSize ?? this.cacheSize,
    );
  }
}

class PerformanceService extends ChangeNotifier {
  static const String _gpuBackendKey = 'performance_gpu_backend';
  static const String _performanceLevelKey = 'performance_level';
  static const String _enableGpuKey = 'performance_enable_gpu';
  static const String _enableVsyncKey = 'performance_enable_vsync';
  static const String _targetFrameRateKey = 'performance_target_fps';
  static const String _enableMultithreadingKey = 'performance_multithreading';
  static const String _enableCacheOptimizationKey = 'performance_cache_opt';
  static const String _fpsLimitKey = 'performance_fps_limit';
  static const String _cacheSizeKey = 'performance_cache_size';

  SharedPreferences? _prefs;
  PerformanceConfig _config = const PerformanceConfig();

  final List<FrameTimingInfo> _frameTimings = [];
  static const int _maxFrameTimings = 120;

  double _averageFrameTime = 0.0;
  double _gpuUsage = 0.0;
  int _droppedFrames = 0;
  bool _isMonitoring = false;
  int _currentCacheUsage = 0;

  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  PerformanceConfig get config => _config;
  double get averageFrameTime => _averageFrameTime;
  double get gpuUsage => _gpuUsage;
  int get droppedFrames => _droppedFrames;
  bool get isMonitoring => _isMonitoring;
  List<FrameTimingInfo> get frameTimings => List.unmodifiable(_frameTimings);
  int get currentCacheUsage => _currentCacheUsage;
  int get maxCacheBytes => _config.cacheSize.maxCacheBytes;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadConfig();
  }

  void _loadConfig() {
    if (_prefs == null) return;

    final gpuBackendIndex = _prefs!.getInt(_gpuBackendKey) ?? 0;
    final perfLevelIndex = _prefs!.getInt(_performanceLevelKey) ?? 2;
    final enableGpu = _prefs!.getBool(_enableGpuKey) ?? true;
    final enableVsync = _prefs!.getBool(_enableVsyncKey) ?? true;
    final targetFps = _prefs!.getInt(_targetFrameRateKey) ?? 60;
    final enableMultithreading =
        _prefs!.getBool(_enableMultithreadingKey) ?? true;
    final enableCacheOpt = _prefs!.getBool(_enableCacheOptimizationKey) ?? true;
    final fpsLimitIndex = _prefs!.getInt(_fpsLimitKey) ?? 1;
    final cacheSizeIndex = _prefs!.getInt(_cacheSizeKey) ?? 1;

    _config = PerformanceConfig(
      gpuBackend: GpuBackend.values[gpuBackendIndex],
      performanceLevel: PerformanceLevel.values[perfLevelIndex],
      enableGpuAcceleration: enableGpu,
      enableVsync: enableVsync,
      targetFrameRate: targetFps,
      enableMultithreading: enableMultithreading,
      enableCacheOptimization: enableCacheOpt,
      fpsLimit: FpsLimit.values[fpsLimitIndex],
      cacheSize: CacheSize.values[cacheSizeIndex],
    );
    notifyListeners();
  }

  Future<void> updateConfig(PerformanceConfig newConfig) async {
    if (_prefs == null) return;

    await _prefs!.setInt(_gpuBackendKey, newConfig.gpuBackend.index);
    await _prefs!.setInt(
      _performanceLevelKey,
      newConfig.performanceLevel.index,
    );
    await _prefs!.setBool(_enableGpuKey, newConfig.enableGpuAcceleration);
    await _prefs!.setBool(_enableVsyncKey, newConfig.enableVsync);
    await _prefs!.setInt(_targetFrameRateKey, newConfig.targetFrameRate);
    await _prefs!.setBool(
      _enableMultithreadingKey,
      newConfig.enableMultithreading,
    );
    await _prefs!.setBool(
      _enableCacheOptimizationKey,
      newConfig.enableCacheOptimization,
    );
    await _prefs!.setInt(_fpsLimitKey, newConfig.fpsLimit.index);
    await _prefs!.setInt(_cacheSizeKey, newConfig.cacheSize.index);

    _config = newConfig;
    notifyListeners();
  }

  Future<void> setGpuBackend(GpuBackend backend) async {
    await updateConfig(_config.copyWith(gpuBackend: backend));
  }

  Future<void> setPerformanceLevel(PerformanceLevel level) async {
    final targetFps = switch (level) {
      PerformanceLevel.low => 30,
      PerformanceLevel.medium => 60,
      PerformanceLevel.high => 60,
      PerformanceLevel.ultra => 120,
    };

    await updateConfig(
      _config.copyWith(performanceLevel: level, targetFrameRate: targetFps),
    );
  }

  Future<void> setEnableGpuAcceleration(bool enable) async {
    await updateConfig(_config.copyWith(enableGpuAcceleration: enable));
  }

  Future<void> setEnableVsync(bool enable) async {
    await updateConfig(_config.copyWith(enableVsync: enable));
  }

  Future<void> setTargetFrameRate(int fps) async {
    await updateConfig(_config.copyWith(targetFrameRate: fps));
  }

  Future<void> setFpsLimit(FpsLimit limit) async {
    await updateConfig(_config.copyWith(fpsLimit: limit));
  }

  Future<void> setCacheSize(CacheSize size) async {
    await updateConfig(_config.copyWith(cacheSize: size));
  }

  void updateCacheUsage(int bytes) {
    _currentCacheUsage = bytes;
    notifyListeners();
  }

  bool shouldClearCache(int newBytes) {
    final maxBytes = _config.cacheSize.maxCacheBytes;
    if (maxBytes < 0) return false;
    return _currentCacheUsage + newBytes > maxBytes;
  }

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _frameTimings.clear();
    _droppedFrames = 0;
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0;
      final buildTime = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterTime = timing.rasterDuration.inMicroseconds / 1000.0;

      final isDropped = frameTime > (1000.0 / _config.targetFrameRate) * 1.5;
      if (isDropped) {
        _droppedFrames++;
      }

      _frameTimings.add(
        FrameTimingInfo(
          frameTime: frameTime,
          buildTime: buildTime,
          rasterTime: rasterTime,
          timestamp: DateTime.now(),
          isDropped: isDropped,
        ),
      );

      if (_frameTimings.length > _maxFrameTimings) {
        _frameTimings.removeAt(0);
      }
    }

    _calculateMetrics();
    notifyListeners();
  }

  void _calculateMetrics() {
    if (_frameTimings.isEmpty) return;

    final recentTimings = _frameTimings.length > 60
        ? _frameTimings.sublist(_frameTimings.length - 60)
        : _frameTimings;

    _averageFrameTime =
        recentTimings.map((t) => t.frameTime).reduce((a, b) => a + b) /
        recentTimings.length;

    final avgRasterTime =
        recentTimings.map((t) => t.rasterTime).reduce((a, b) => a + b) /
        recentTimings.length;

    final targetFps = _config.effectiveFrameRate.toDouble();
    _gpuUsage = targetFps > 0
        ? (avgRasterTime / (1000.0 / targetFps) * 100).clamp(0.0, 100.0)
        : 0.0;
  }

  void resetMetrics() {
    _frameTimings.clear();
    _averageFrameTime = 0.0;
    _gpuUsage = 0.0;
    _droppedFrames = 0;
    notifyListeners();
  }

  static String getPlatformDefaultBackend() {
    if (Platform.isMacOS || Platform.isIOS) {
      return 'Metal';
    } else if (Platform.isWindows) {
      return 'DirectX/Vulkan';
    } else if (Platform.isLinux) {
      return 'Vulkan/OpenGL';
    } else if (Platform.isAndroid) {
      return 'Vulkan/OpenGL';
    }
    return 'OpenGL';
  }

  static bool get isImpellerSupported {
    if (Platform.isMacOS || Platform.isIOS) {
      return true;
    } else if (Platform.isAndroid) {
      return true;
    }
    return false;
  }

  static String getImpellerStatus() {
    if (Platform.isMacOS || Platform.isIOS) {
      return 'Impeller Metal 后端已启用';
    } else if (Platform.isAndroid) {
      return 'Impeller OpenGL/Vulkan 后端已启用';
    } else if (Platform.isWindows) {
      return 'Impeller 实验性支持（需要手动启用）';
    } else if (Platform.isLinux) {
      return 'Impeller 实验性支持（需要手动启用）';
    }
    return 'Impeller 不支持此平台';
  }

  PerformanceMetrics getCurrentMetrics() {
    return PerformanceMetrics(
      averageFrameTime: _averageFrameTime,
      gpuUsage: _gpuUsage,
      droppedFrames: _droppedFrames,
      frameRate: _averageFrameTime > 0 ? 1000.0 / _averageFrameTime : 0,
      isGpuAccelerated: _config.enableGpuAcceleration,
      currentBackend: _config.gpuBackend,
      platformBackend: getPlatformDefaultBackend(),
      fpsLimit: _config.fpsLimit,
      cacheSize: _config.cacheSize,
      currentCacheUsage: _currentCacheUsage,
      maxCacheBytes: _config.cacheSize.maxCacheBytes,
    );
  }
}

class FrameTimingInfo {
  final double frameTime;
  final double buildTime;
  final double rasterTime;
  final DateTime timestamp;
  final bool isDropped;

  const FrameTimingInfo({
    required this.frameTime,
    required this.buildTime,
    required this.rasterTime,
    required this.timestamp,
    this.isDropped = false,
  });

  double get fps => frameTime > 0 ? 1000.0 / frameTime : 0;
}

class PerformanceMetrics {
  final double averageFrameTime;
  final double gpuUsage;
  final int droppedFrames;
  final double frameRate;
  final bool isGpuAccelerated;
  final GpuBackend currentBackend;
  final String platformBackend;
  final FpsLimit fpsLimit;
  final CacheSize cacheSize;
  final int currentCacheUsage;
  final int maxCacheBytes;

  const PerformanceMetrics({
    required this.averageFrameTime,
    required this.gpuUsage,
    required this.droppedFrames,
    required this.frameRate,
    required this.isGpuAccelerated,
    required this.currentBackend,
    required this.platformBackend,
    required this.fpsLimit,
    required this.cacheSize,
    this.currentCacheUsage = 0,
    this.maxCacheBytes = 100 * 1024 * 1024,
  });

  String get frameRateFormatted => '${frameRate.toStringAsFixed(1)} FPS';
  String get frameTimeFormatted => '${averageFrameTime.toStringAsFixed(2)} ms';
  String get gpuUsageFormatted => '${gpuUsage.toStringAsFixed(1)}%';
  String get cacheUsageFormatted {
    if (maxCacheBytes < 0) {
      return '${(currentCacheUsage / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(currentCacheUsage / 1024 / 1024).toStringAsFixed(1)} / ${(maxCacheBytes / 1024 / 1024).toStringAsFixed(0)} MB';
  }

  PerformanceRating get performanceRating {
    if (frameRate >= 55) return PerformanceRating.excellent;
    if (frameRate >= 45) return PerformanceRating.good;
    if (frameRate >= 30) return PerformanceRating.fair;
    return PerformanceRating.poor;
  }
}

enum PerformanceRating { excellent, good, fair, poor }
